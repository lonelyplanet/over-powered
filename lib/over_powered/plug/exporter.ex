defmodule OverPowered.Plug.Exporter do
  @moduledoc """
  This plug module will intercept requests for metrics by clients
  and supply them with stats collected by OP.Profiles.PlugInstrumenter.
  These metrics should include VM statistics as well as request statistics
  of different endpoints.  For more information you may want to refer to:

	https://github.com/deadtrickster/prometheus-plugs
  """
  use Prometheus.PlugExporter
end
