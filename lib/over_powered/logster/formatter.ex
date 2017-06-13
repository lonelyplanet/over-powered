defmodule OverPowered.Logster.Formatter do
  def format(params) do
    params
    |> Enum.into(%{})
    |> transform!
    |> Poison.encode!
  end

  defp transform!(%{request_id: id}=params) do
    params
    |> Map.delete(:request_id)
    |> Map.put(:tracetoken, id)
    |> Map.put("@timestamp", timestamp())
    |> Map.put_new(:level, "INFO")
    |> Map.put_new(:message, "")
  end

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
