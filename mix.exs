defmodule Together.MixProject do
  use Mix.Project

  def project do
    [
      app: :together,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      docs: docs(),
      name: "Together Elixir Common",
      source_url: "https://github.com/togethercomputer/elixir-common",
      homepage_url: "https://github.com/togethercomputer/elixir-common"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.5", optional: true},
      {:ex_doc, "~> 0.38", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md": [title: "Introduction"],
        LICENSE: [title: "License"]
      ],
      formatters: ["html"],
      groups_for_modules: [
        Testing: [~r/Together.Test/]
      ],
      source_ref: "main"
    ]
  end
end
