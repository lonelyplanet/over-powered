defmodule OverPowered.Ids do
  @moduledoc """
    A module to provide effecient id only pagination through a data collection.

    Given a connection and specific options; this tool is designed to send a
    json-api payload which has a barebones payload that can be used for sitemap
    generation.

    The options are:

      * repo:  The application Repo used to fetch database records
      * scope: query to page through
      * url:   A string template for each record's "self" url
      * type:  Each document's "type" field
      * extra_fields:  Sometimes you need more then the `id` field, this optional
                       option should be a list of fields as atoms to select, note
                       that `:id` is automatically included and is not needed in
                       this list
  """

  import Plug.Conn
  import Ecto.Query, only: [from: 2]

  def fetch(conn, opts) do
    opts = setup(opts)

    opts
    |> select
    |> order
    |> offset(conn)
    |> limit(conn, opts)
    |> opts[:repo].all
    |> json_api(conn, opts)
  end

  defp setup(opts) do
    opts
    |> Keyword.put_new(:default_limit, 1000)
    |> Keyword.put_new(:extra_fields, [])
    |> ensure_opt(:repo, "An Ecto Repo is required!")
    |> ensure_opt(:type, "A document type is required!")
    |> ensure_opt(:scope, "A query scope is required!")
    |> ensure_opt(:url, "A route is required for each object!")
  end


  defp order(query) do
    from(query, order_by: [asc: :id])
  end

  defp select(opts) do
    fields = [:id | opts[:extra_fields]]
    from(q in opts[:scope], select: ^fields)
  end

  defp offset(query, %{params: %{"last_id"=>id}}) do
    from(q in query, where: q.id > ^id)
  end
  defp offset(query, _), do: query

  defp limit(query, conn, opts) do
    from(query, limit: ^limit_from_conn(conn, opts))
  end

  defp limit_from_conn(%{params: %{"page"=>%{"limit"=>limit}}}, opts) do
    case Integer.parse(limit) do
      {int, _} -> int
      _ -> opts[:default_limit]
    end
  end
  defp limit_from_conn(_, opts), do: opts[:default_limit]

  defp ensure_opt(opts, key, msg) do
    opts[key] || raise msg
    opts
  end

  defp json_api(data, conn, opts) do
    ids =
      %{}
      |> add_links(data, conn, opts)
      |> add_data(data, opts)
      |> Poison.encode!

    conn
    |> put_resp_content_type("application/vnd.api+json; charset=utf-8")
    |> send_resp(200, ids)
  end

  defp add_data(payload, data, opts) do
    documents =
      Enum.map(data, fn rec ->
        %{attributes: %{},
          type: opts[:type],
          links: %{ self: build_self(rec, opts) },
          relationships: %{},
          id: "#{rec.id}"}
      end)

    put_in(payload[:data], documents)
  end

  def build_self(rec, opts) do
    pattern = opts[:url]
    data = rec |> Map.take([:id | opts[:extra_fields]])
    Enum.reduce(data, pattern, fn {key, val}, url ->
      String.replace(url, ":#{key}", "#{val}")
    end)
  end

  defp add_links(payload, [], conn, _opts) do
    put_in(payload[:links], %{:self => conn.request_path})
  end
  defp add_links(payload, data, conn, opts) do
    next_page_params = %{
      last_id: data |> List.last |> Map.get(:id),
      page: %{
        limit: limit_from_conn(conn, opts)
      }
    } |> Plug.Conn.Query.encode

    put_in(payload[:links],
     %{:self => conn.request_path,
       :next => "#{conn.request_path}?#{next_page_params}"})
  end
end
