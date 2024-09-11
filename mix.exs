defmodule JaSerializer.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ja_serializer,
      version: "0.12.0",
      elixir: "~> 1.1",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      source_url: "https://github.com/vt-elixir/ja_serializer",
      package: package(),
      description: description(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger, :inflex, :plug, :poison]]
  end

  defp deps do
    [
      {:inflex, "~> 1.4 or ~> 2.0"},
      {:plug, "> 1.0.0"},
      {:poison, ">= 1.4.0"},
      {:ecto, "~> 2.0 or ~> 3.0"},
      {:phoenix, ">= 1.7.0"},
      {:earmark, "~> 1.4", only: :dev},
      {:inch_ex, "~> 2.0", only: :docs},
      {:scrivener, "~> 2.0"},
      {:benchfella, "~> 0.3.0", only: :dev},
      {:ex_doc, "~> 0.7", only: :dev},
      {:dialyxir, "~> 1.4", only: :dev},
      {:credo, "~> 1.6", only: :dev}
    ]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      maintainers: ["Alan Peabody"],
      links: %{
        "GitHub" => "https://github.com/vt-elixir/ja_serializer"
      }
    ]
  end

  defp description do
    """
    A serialization library implementing the jsonapi.org 1.0 spec suitable for
    use building JSON APIs in Pheonix and any other Plug based framework or app.
    """
  end
end
