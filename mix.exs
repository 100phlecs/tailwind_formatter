defmodule TailwindFormatter.MixProject do
  use Mix.Project

  @version "0.3.3"
  @url "https://github.com/100phlecs/tailwind_formatter"

  def project do
    [
      app: :tailwind_formatter,
      version: @version,
      elixir: "~> 1.13",
      name: "TailwindFormatter",
      description: "A Mix formatter that sorts your Tailwind classes",
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "TailwindFormatter",
      source_ref: "v#{@version}",
      source_url: @url
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["100phlecs"],
      links: %{"GitHub" => @url}
    }
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # docs
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:phoenix_live_view, ">= 0.17.6", optional: true}
    ]
  end
end
