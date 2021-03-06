defmodule OverPowered.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Setup Prometheus buckets
    OverPowered.Plug.Instrumenter.setup()
    OverPowered.Plug.Exporter.setup()

    # Define workers and child supervisors to be supervised
    children = [
      worker(Cachex, [:token_cache, [limit: 1000]])
      # Starts a worker by calling: OverPowered.Worker.start_link(arg1, arg2, arg3)
      # worker(OverPowered.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OverPowered.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
