defmodule SbrokerPlayground.MixProject do
  use Mix.Project

  def project do
    [
      app: :sbroker_playground,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:sbroker, "~> 1.0.0"},
      {:poolboy, "~> 1.5"},
      {:statistics, "~> 0.6"},
      {:io_ansi_table, "~> 0.4"},
      {:optimus, "~> 0.1.0"}
    ]
  end
end
