if Code.ensure_loaded?(Phoenix.LiveView.HTMLFormatter) do
  defmodule TailwindFormatter.MultiFormatter do
    if Version.match?(System.version(), ">= 1.13.0") do
      @behaviour Mix.Tasks.Format
    end

    def features(_opts) do
      [sigils: [:H], extensions: [".heex"]]
    end

    def format(contents, opts) do
      Phoenix.LiveView.HTMLFormatter.format(contents, opts)
      |> TailwindFormatter.format(opts)
    end
  end
end
