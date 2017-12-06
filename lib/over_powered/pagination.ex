defmodule OverPowered.Pagination do
  @moduledoc """
  Responsible for simple pagination calculations and helper functions.
  """

  @default_limit 10
  @default_offset 0

  defstruct limit: @default_limit, offset: @default_offset

  @doc """
  Takes map params that would come from plug and returns a Pagination struct

  ## Examples

    iex> %{"page"=>%{"limit"=>"5", "offset"=>"5"}}
    ...> |> OverPowered.Pagination.from_params()
    %OverPowered.Pagination{limit: 5, offset: 5}

    iex> OverPowered.Pagination.from_params(%{"garbage"=>"in"})
    %OverPowered.Pagination{limit: 10, offset: 0}
  """
  def from_params(%{"page"=>params}) when is_map(params) do
    with {limit, _} <- Integer.parse(params["limit"] || "#{@default_limit}"),
         {offset, _} <- Integer.parse(params["offset"] || "#{@default_offset}")
    do
      %__MODULE__{limit: limit, offset: offset}
    else
      _ -> %__MODULE__{limit: @default_limit, offset: @default_offset}
    end
  end
  def from_params(_) do
    %__MODULE__{limit: @default_limit, offset: @default_offset}
  end

  @doc """
  Given a pagination struct, returns params that could have come from a request

  ## Example

    iex> %OverPowered.Pagination{limit: 5, offset: 5}
    ...> |> OverPowered.Pagination.to_params()
    %{"page"=>%{"offset"=>"5", "limit"=>"5"}}
  """
  def to_params(%__MODULE__{offset: offset, limit: limit}) do
    %{"page"=>%{"limit"=>"#{limit}", "offset"=>"#{offset}"}}
  end

  @doc """
  Quick helper function to change the limit of a pagination by a delta

  ## Example

    iex> %OverPowered.Pagination{limit: 15, offset: 5}
    ...> |> OverPowered.Pagination.increase_limit_by(1)
    %OverPowered.Pagination{limit: 16, offset: 5}
  """
  def increase_limit_by(pagination=%__MODULE__{limit: limit}, delta)
    when is_integer(delta), do: %{ pagination | limit: limit + delta }

  ## Insulate Ecto Features so as to not require that ecto be needed
  ## in projects that don't use a database
  if Code.ensure_loaded?(Ecto) do
    @doc """
    Given a query, this will apply the limit and offset to it

    ## Example

      iex> alias OverPowered.Pagination
      iex> import Ecto.Query, only: [from: 1]
      iex> query = from(a in "apples")
      iex> %Pagination{limit: 100, offset: 100} |> Pagination.apply_to_query(query)
      #Ecto.Query<from a in "apples", limit: ^100, offset: ^100>

    """
    def apply_to_query(%__MODULE__{limit: limit, offset: offset}, query) do
      import Ecto.Query
      from(query, limit: ^limit, offset: ^offset)
    end
  end

  @doc """
  Builds an url with pagination params added to it based on provided Plug.Conn

  ## Example

    iex> conn = %Plug.Conn{query_params: %{rofl: :copter}, request_path: "/foo"}
    iex> page = %OverPowered.Pagination{limit: 100, offset: 300}
    iex> OverPowered.Pagination.build_url(page, conn)
    "/foo?rofl=copter&page[limit]=100&page[offset]=300"
  """
  def build_url(pagination, %{query_params: query_params, request_path: path}) do
    query_string =
      query_params
      |> Map.merge(to_params(pagination))
      |> Plug.Conn.Query.encode

    "#{path}?#{query_string}"
  end

  @doc """
  Helper that returns a page struct that would be the "next" page of values
  """
  def next_page(%__MODULE__{limit: limit, offset: offset}) do
    %__MODULE__{limit: limit, offset: offset+limit}
  end

  @doc """
  Helper that returns a page struct which would be the first page with same limit
  """
  def first_page(%__MODULE__{limit: limit}) do
    %__MODULE__{offset: 0, limit: limit}
  end

  @doc """
  Helper that returns what would be the previous page struct
  """
  def prev_page(%__MODULE__{limit: limit, offset: offset}) when limit > offset do
    %__MODULE__{limit: limit, offset: 0}
  end
  def prev_page(%__MODULE__{limit: limit, offset: offset}) do
    %__MODULE__{limit: limit, offset: offset-limit}
  end
end
