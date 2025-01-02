defmodule TailwindFormatter.MixProject do
  use Mix.Project

  @version "0.4.3"
  @url "https://github.com/100phlecs/tailwind_formatter"

  def project do
    [
      app: :tailwind_formatter,
      version: @version,
      elixir: "~> 1.15",
      name: "TailwindFormatter",
      description: "A Mix formatter that sorts your Tailwind classes",
      deps: deps(),
      docs: docs(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env())
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
      source_url: @url,
      extras: ["CHANGELOG.md"]
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["100phlecs"],
      links: %{"GitHub" => @url},
      files:
        ~w(assets/js/* lib priv) ++
          ~w(CHANGELOG.md LICENSE.md mix.exs README.md .formatter.exs)
    }
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tailwind, "~> 0.2", only: :dev},
      {:benchee, "~> 1.0", only: [:dev], optional: true},
      # docs
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "src", "test"]
  defp elixirc_paths(:dev), do: ["lib", "src", "bench"]
  defp elixirc_paths(:release), do: ["lib", "src"]
  defp elixirc_paths(_), do: ["lib", "src"]
end
