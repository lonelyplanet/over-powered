defmodule OverPowered.Plug.Authorization do
  @moduledoc """
  This is a middleware plug system that is meant to listen in for an authorization
  header with a bearer token.  If one is detected and there isn't an auth structure
  present this plug will use the `Connect2ID` client to pass along the token to
  connect2id to be inspected and then parses the response to a simple known structure
  defined by this plug.

  For more information on plugs see: https://hexdocs.pm/plug/readme.html
  """
  import Plug.Conn
  alias OverPowered.Connect2ID

  defmodule Error do
    defexception [:message]
  end

  @split_scope ~r/^(op:.*):([rduc])$/

  defstruct scopes: %{}, id: ""

  def init(opts), do: opts

  @doc """
  The middleware logic of this plug is pretty strait forward.  If there is auth
  structure already located in the connection then it passes the connection along
  with no processing; this is mainly for testing so we can bypass this.  If no
  auth structure is found then a check is made for an `authorization` header with
  a bearer token.  If one is found it calls out to connect2id with it otherwise it
  drops in an empty auth structure which is essentially an anonymous request.

  **NOTE** The default functionality for a bad auth request is to treat it as an
  anonymous request; if instead you would like to break the flow of the request
  you can set an opt on the plug of `:error_on_bad_auth`.  This will force an
  exception to raise fo `OverPowered.Plug.Authorization.Error`.
  """
  def call(conn=%{private: %{auth: %__MODULE__{}}}, _opts) do
    conn
  end
  def call(conn, opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        put_private(conn, :auth,
          token
          |> Connect2ID.introspect_token
          |> token_to_struct(opts)
        )
      _ ->
        put_private(conn, :auth, %__MODULE__{})
    end
  end

  def parse_scopes(scope_string) do
    scope_string
    |> String.split(" ")
    |> Enum.map(&Regex.run(@split_scope, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce(%{}, fn([_, scope, perm], scopes) ->
      perms = scopes[scope] || []
      Map.put(scopes, scope, [perm_to_atom(perm)|perms])
    end)
  end

  defp perm_to_atom("r"), do: :read
  defp perm_to_atom("d"), do: :delete
  defp perm_to_atom("c"), do: :create
  defp perm_to_atom("u"), do: :update

  defp token_to_struct(%{"active"=>false}, :error_on_bad_auth) do
    raise Error, "Authorization Failed"
  end
  defp token_to_struct(token, _) do
    %__MODULE__{
      scopes: parse_scopes(token["scope"] || ""),
      id: token["sub"] || ""
    }
  end
end
