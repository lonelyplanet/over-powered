defmodule OverPowered.Endpoint do
  defmacro __using__(_) do
    quote do
      plug Plug.RequestId, http_header: "x-trace-token"
      plug LoggerJSON.Plug, metadata_formatter: OverPowered.Logging.PlugMetadataFormatter
      plug OverPowered.Plug.Exporter
    end
  end
end
