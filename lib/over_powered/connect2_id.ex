defmodule OverPowered.Connect2ID do
  @moduledoc """
  This is a simple Connect2ID client to perform any actions needed against
  the open planet connect2id server.  For more information on the overall
  api that is supported visit: https://connect2id.com/products/server/docs/api

  In order to use this client it currently only supports basic authorization and
  pulls in this information from environment variables.  The three variable names
  you'll need are:

    * CONNECT2ID_CLIENT_BASE_URL
    * CONNECT2ID_CLIENT_ID
    * CONNECT2ID_CLIENT_SECRET

  """
  use HTTPotion.Base

  @doc """
  Used to check the access token presented to a resource server to verify it's
  integrity and get information about the client requesting a resource.  For more
  information visit:

  https://connect2id.com/products/server/docs/api/token-introspection
  """
  def introspect_token(token) do
    "/token/introspect"
    |> post(body: "token=" <> URI.encode_www_form(token))
    |> case do
      %{body: body, status_code: 200} ->
        body
      error ->
        raise "Bad response when posting to /token/intropsect [#{error}]"
    end
  end

  defp process_response_body(body) do
    body |> IO.iodata_to_binary |> Poison.decode!
  end

  defp process_url(url) do
    "#{System.get_env("CONNECT2ID_CLIENT_BASE_URL")}" <> url
  end

  defp process_request_headers(headers) do
    headers ++ [
      {"Authorization", "Basic #{encoded_creds()}"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]
  end

  defp encoded_creds do
     id = System.get_env("CONNECT2ID_CLIENT_ID")
     secret = System.get_env("CONNECT2ID_CLIENT_SECRET")

     if is_nil(id) || is_nil(secret) do
       raise "CONNECT2ID ENVs ARE MISSING"
     end

    "#{id}:#{secret}" |> Base.encode64
  end
end
