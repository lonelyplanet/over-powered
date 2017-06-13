defmodule OverPowered.Plug.Instrumenter do
  @moduledoc """
  This is a Plug middleware that records metrics on requests when it is put
  into the pipeline of a request.  For more information you may want to
  refer to the hex package that does the heavy lifting:

	https://github.com/deadtrickster/prometheus-plugs
  """

  use Prometheus.PlugPipelineInstrumenter

  def label_value(:controller_action, %Plug.Conn{private: private}) do
    case [private[:phoenix_controller], private[:phoenix_action]] do
      [nil, nil] -> "none"
      [controller, action] -> "#{controller}/#{action}"
    end
  end
end
