input =
  File.read!("test/tailwind_formatter_test.exs")
  |> String.split("\"\"\"")
  |> Enum.drop_every(2)

big_file_input  =
  input
  |> Enum.join()
  |> String.duplicate(250)

many_file_input =
  Enum.reduce(1..250, input, fn _i, acc -> input ++ acc end)

Benchee.run(%{
  "format big file" => fn -> TailwindFormatter.format(big_file_input, []) end,
  "format many files" => fn -> Enum.each(many_file_input, &TailwindFormatter.format(&1, [])) end
})
