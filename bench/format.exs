input =
  File.read!("test/tailwind_formatter_test.exs")
  |> String.split("\"\"\"")
  |> Enum.drop_every(2)
  |> Enum.join()
  |> String.duplicate(1000)

Benchee.run(%{
  "format" => fn -> TailwindFormatter.format(input, []) end
})
