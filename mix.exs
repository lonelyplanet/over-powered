defmodule OverPowered.Mixfile do
  use Mix.Project

  def project do
    [
      app: :over_powered,
      version: "0.1.0",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :cachex], mod: {OverPowered.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:check_up, github: "lonelyplanet/check_up", branch: "dh/update"},
      {:op_auth, github: "lonelyplanet/op-auth", branch: "dh/update"},
      {:prometheus_plugs, "~> 1.1"},
      {:httpotion, "~> 3.0.0"},
      {:ecto, "~> 3.2"},
      {:cachex, "~> 3.0"},
      {:retry, "~> 0.11"},
      {:logger_json, "~> 3.0"},
      {:jason, "~> 1.1"}
    ]
  end
end
