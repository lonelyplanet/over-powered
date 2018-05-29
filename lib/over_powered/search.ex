defmodule OverPowered.Search do
  @moduledoc """
  Searching abstraction that supports finding data by id or via a set of
  parameters.  It also understands pagination parameters and returns data
  in a format that can be directly passed to a ja_serializer view for
  rendering.
  To utilize the two lookups it expects a behaviour module to be provided
  that implements five different functions.
  * find_by_id_scope/2 - the scope from which to lookup ids, this is passed
    the parameters from a request
  * find_by_id_preloads/1 - this is passed the lookup scope and is expected
    to return a scope with any preload requests attached with it
  * find_by_params_scope/2 - same as the find_by_id scope, this is handy if
    you want to do any kinds of default joins from the get-go
  * find_by_params_preloads/1 - same as the find_by_id_preloads
  * before_query/3 - gets the context as an atom of which query it is, be it
    either `:find_by_id` or `:find_by_params` for the first param, the plug
    connection as the second, param, and the queryable as the third
  * filter/3 - this is where the heavily lifting of parameter searching
    takes place.  All keys from a "filter" parameter are passed as a list
    of keys, the value of the end leaf, and the query to be modified. Take
    the following example: ?filter[foo][bar]=baz
    This will match on a filter function like this:
    ```elixir
    def filter(~w(foo far), what, query) do
      import Ecto.Query
      from(q in query, where: q.bar == ^what)
    end
    ```
  * sort/3 - this provides a window into the json-api sorting specification
    and sends every field that has been requested for sort by the client in
    the form of query, field, direction and is expected to return a query.
    The direction is either `:asc` or `:desc` and the field will always be
    a string. A query like `?sort=name,-created_at` becomes to calls to
    sort in the following order:
    1. `sort(query, "name", :asc)`
    2. `sort(query, "created_at", :desc)`
  Here is an example of a zero-opt implementation of a search for an
  ecto module `Foo`:
  ```elixir
  defmodule FooSearch do
    use OverPowered.Search, repo: Foo.Repo
    import Ecto.Query
    def find_by_id_scope(%{"id"=>id}, _), do: from(f in Foo, where: f.id == ^id)
    def find_by_id_preloads(query), do: query
    def find_by_params_scope(_,_), do: Foo
    def find_by_params_preloads(query), do: query
    def filter(_, _, query), do: query
    def before_query(query, _, _), do: query
    def sort(query, _, _), do: query
  end
  ```
  """

  @callback find_by_id_scope(map(), Plug.Conn.t) :: Ecto.Queryable.t
  @callback find_by_id_preloads(Ecto.Queryable.t) :: Ecto.Queryable.t
  @callback find_by_params_scope(map(), Plug.Conn.t) :: Ecto.Queryable.t
  @callback find_by_params_preloads(Ecto.Queryable.t) :: Ecto.Queryable.t
  @callback filter(list(), any(), Ecto.Queryable.t) :: Ecto.Queryable.t
  @callback before_query(Ecto.Queryable.t, atom(), Plug.Conn.t) :: Ecto.Queryable.t
  @callback sort(Ecto.Queryable.t, String.t, atom()) :: Ecto.Queryable.t
  @callback fetch(Ecto.Queryable.t, atom(), Plug.Conn.t) :: [any()] | any()

  alias OverPowered.Pagination

  defmacro __using__(opts \\ []) do
    unless Keyword.has_key?(opts, :repo) do
      raise ArgumentError, message: ":repo is required"
    end

    quote do
      @behaviour OverPowered.Search

      def fetch(query, :find_by_id, _conn), do: unquote(opts)[:repo].one(query)
      def fetch(query, :find_by_params, _conn), do: unquote(opts)[:repo].all(query)

      def sort(query, _field, direction), do: query

      def before_query(query, _which, _conn), do: query

      def find_by_id_scope(_params, _conn), do: raise UndefinedFunctionError

      def find_by_id_preloads(query), do: query

      def find_by_params_scope(_params, _conn), do: raise UndefinedFunctionError

      def find_by_params_preloads(query), do: query

      def filter(_keys, _value, query), do: query

      defoverridable fetch: 3, sort: 3, before_query: 3,
                     find_by_id_scope: 2, find_by_id_preloads: 1,
                     find_by_params_scope: 2, find_by_params_preloads: 1,
                     filter: 3
    end
  end

  @doc """
  Simple lookup by id for a module that has implemented the Search behaviour
  and returns data that can be directly rendered for a ja_serializer view.
  """
  def find_by_id(searchable, params, conn \\ nil) do
    searchable.find_by_id_scope(params, conn)
    |> searchable.find_by_id_preloads()
    |> searchable.before_query(:find_by_id, conn)
    |> searchable.fetch(:find_by_id, conn)
    |> assign_data(conn)
  end

  @doc """
  Uses filter function defined on a module implementing Search behaviour
  and performs any pagination opts passed or defaults to a preset of 10.
  Returns results that can directly rendered with a ja_serializer view.
  """
  def find_by_params(searchable, params, conn \\ nil) do
    searchable.find_by_params_scope(params, conn)
    |> filter_with_params(params, searchable)
    |> searchable.find_by_params_preloads()
    |> paginate(params)
    |> searchable.before_query(:find_by_params, conn)
    |> sort_if_needed(searchable, params)
    |> searchable.fetch(:find_by_params, conn)
    |> assign_data(conn)
  end

  def assign_data(data, nil), do: [data: data]
  def assign_data(data, conn) when is_list(data) do
    import Pagination
    page = from_params(conn.query_params)

    [data: one_off_the_end(data, page.limit),
      opts: [page: pages(data, page, conn)]]
  end
  def assign_data(data, conn) do
    [data: data,
      opts: [page: [{:self, "#{conn.request_path}"}]]]
  end

  defp sort_if_needed(query, searchable, %{"sort"=>fields_str})
       when is_binary(fields_str) do
    fields =
      String.split(fields_str, ",")
      |> Enum.map(fn
        "-"<>field -> {field, :desc}
        field -> {field, :asc}
      end)

    Enum.reduce(fields, query, fn {field, dir}, query ->
      searchable.sort(query, field, dir)
    end)
  end
  defp sort_if_needed(query, _searchable, _params), do: query

  defp filter_with_params(query, %{"filter"=>params}, searchable)
       when is_map(params) do
    decompose_keys(params)
    |> Enum.reduce(query, fn {keys, value}, query ->
      searchable.filter(keys, value, query)
    end)
  end
  defp filter_with_params(query, _nomatch, _), do: query

  defp decompose_keys(map) do
    map
    |> Enum.reduce([], &decompose_keys/2)
    |> List.flatten
    |> Enum.map(&reverse_keys/1)
  end
  defp decompose_keys({key, value}, sets) when not(is_list(key)) do
    decompose_keys({[key], value}, sets)
  end
  defp decompose_keys({keys, value}, sets) when not(is_map(value)) do
    [{keys, value} | sets]
  end
  defp decompose_keys({keys, map}, sets) do
    Enum.reduce(map, sets, fn {key,value}, acc ->
      decompose_keys({[key | keys], value}, acc)
    end)
  end

  defp reverse_keys({keys, value}), do: {Enum.reverse(keys), value}

  defp paginate(query, params) do
    import Pagination
    params
    |> from_params
    |> increase_limit_by(1)
    |> apply_to_query(query)
  end

  defp pages(data, %{offset: 0, limit: limit}=page, conn)
       when length(data) <= limit do
    import Pagination
    [{:self, build_url(page, conn)},
      {:first, build_url(first_page(page), conn)}]
  end
  defp pages(data, %{offset: 0, limit: limit}=page, conn)
       when length(data) > limit do
    import Pagination
    [{:self, build_url(page, conn)},
      {:first, build_url(first_page(page), conn)},
      {:next, build_url(next_page(page), conn)}]
  end
  defp pages(data, %{limit: limit}=page, conn)
       when length(data) > limit do
    import Pagination
    [{:self, build_url(page, conn)},
      {:first, build_url(first_page(page), conn)},
      {:prev, build_url(prev_page(page), conn)},
      {:next, build_url(next_page(page), conn)}]
  end
  defp pages(_, page, conn) do
    import Pagination
    [{:self, build_url(page, conn)},
      {:first, build_url(first_page(page), conn)},
      {:prev, build_url(prev_page(page), conn)}]
  end

  defp one_off_the_end(list, limit) when length(list) > limit do
    {_, result} = List.pop_at(list, -1)
    result
  end
  defp one_off_the_end(list, _), do: list
end