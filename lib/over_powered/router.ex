defmodule OverPowered.Router do
  defmacro __using__(_) do
    quote do
      pipeline :instrumentation do
        plug OverPowered.Plug.Instrumenter
      end

      pipeline :auth do
        plug OP.Auth.Plug
      end

      import OverPowered.Router, only: [health_check: 1]
    end
  end

  defmacro health_check(config) do
    quote do
      scope "/health-check" do
        get "/", CheckUp, unquote(config)
      end
    end
  end
end
