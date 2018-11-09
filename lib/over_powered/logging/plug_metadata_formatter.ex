defmodule OverPowered.Logging.PlugMetadataFormatter do

  @doc false
  def build_metadata(conn, latency, _client_version_header) do
    [
      status: conn.status,
      method: conn.method,
      path: conn.request_path,
      duration: System.convert_time_unit(latency, :native, :millisecond),
      params: get_params(conn)
    ]
  end


  defp get_params(%{params: _params = %Plug.Conn.Unfetched{}}), do: %{}

  defp get_params(%{params: params}) do
    params
    |> do_format_values
  end

  def do_format_values(%{} = params), do: params |> Enum.into(%{}, &do_format_value/1)

  def do_format_value({key, value}) when is_binary(value) do
    if String.valid?(value) do
      {key, value}
    else
      {key, URI.encode(value)}
    end
  end

  def do_format_value(val), do: val
end
