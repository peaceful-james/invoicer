defmodule InvoicerPdf.MixProject do
  use Mix.Project

  def project do
    [
      app: :invoicer_pdf,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {InvoicerPdf.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:chromic_pdf, "~> 1.1"},
      {:holidefs, "~> 0.3"},
      {:ecto_sql, "~> 3.0"},
      {:phoenix_ecto, "~> 4.2.1"},
      {:timex, "~> 3.7.5"}
    ]
  end
end
