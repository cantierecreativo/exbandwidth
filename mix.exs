defmodule Exbandwidth.Mixfile do
  use Mix.Project

  def project do
    [app: :exbandwidth,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [], mod: {Exbandwidth, []}]
  end

  defp deps do
    [{:capture_child_io, "~> 0.1.0", only: :test}]
  end
end
