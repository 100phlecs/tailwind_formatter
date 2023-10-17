defmodule Mix.Tasks.Tw.Bench do
  @shortdoc "Runs a simple benchmark to check code optimizations."
  use Mix.Task

  alias TailwindFormatter.HEExTokenizer

  def run([]) do
    input =
      File.read!("test/tailwind_formatter_test.exs")
      |> String.split("\"\"\"")
      |> Enum.drop_every(2)
      |> Enum.join()
      |> String.duplicate(250)

    Benchee.run(
      %{
        "current" => fn -> TailwindFormatter.format(input, []) end,
        "nested" => fn -> format_nested(input, []) end,
        "for" => fn -> format_for(input, []) end
      },
      profile_after: true
    )
  end

  defp format_nested(contents, _opts) do
    contents
    |> HEExTokenizer.tokenize()
    |> Enum.reduce(contents, fn
      {:tag, _name, attrs, _meta}, contents ->
        Enum.reduce(attrs, contents, fn
          {"class", class, _meta}, contents ->
            TailwindFormatter.sort_classes(class, contents)

          _, contents ->
            contents
        end)

      _, contents ->
        contents
    end)
  end

  defp format_for(contents, _opts) do
    for {:tag, _name, attrs, _meta} <- HEExTokenizer.tokenize(contents),
        {"class", class, _meta} <- attrs,
        reduce: contents do
      contents -> TailwindFormatter.sort_classes(class, contents)
    end
  end
end
