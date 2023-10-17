defmodule Mix.Tasks.Tw.Bench do
  @shortdoc "Runs a simple benchmark to check code optimizations."
  use Mix.Task

  def run([]) do
    input =
      File.read!("test/tailwind_formatter_test.exs")
      |> String.split("\"\"\"")
      |> Enum.drop_every(2)
      |> Enum.join()
      |> String.duplicate(250)

    Benchee.run(%{
      "current" => fn -> TailwindFormatter.format(input, []) end
    })
  end
end
