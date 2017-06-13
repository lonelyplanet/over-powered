defmodule OverPowered.Endpoint do
  defmacro __using__(_) do
    quote do
      plug Plug.RequestId, http_header: "x-trace-token"
      plug Logster.Plugs.Logger, formatter: OverPowered.Logster.Formatter
      plug OverPowered.Plug.Exporter
    end
  end
end
