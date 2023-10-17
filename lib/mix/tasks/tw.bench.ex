defmodule Mix.Tasks.Tw.Bench do
  @shortdoc "Runs a simple benchmark to check code optimizations."
  use Mix.Task
  @moduledoc false

  @doc """
   > mix tw.bench
    Compiling 2 files (.ex)
    Generated tailwind_formatter app
    Operating System: macOS
    CPU Information: Apple M1
    Number of Available Cores: 8
    Available memory: 16 GB
    Elixir 1.15.6
    Erlang 26.1.1

    Benchmark suite executing with the following configuration:
    warmup: 2 s
    time: 5 s
    memory time: 0 ns
    reduction time: 0 ns
    parallel: 1
    inputs: none specified
    Estimated total run time: 7 s

    Benchmarking current ...

    Name                    ips        average  deviation         median         99th %
    current              0.0610        16.40 s     ±0.00%        16.40 s        16.40 s


    Name                    ips        average  deviation         median         99th %
    first attempt          0.95         1.06 s     ±1.84%         1.06 s         1.08 s
  """
  def run([]) do
    input =
      File.read!("test/tailwind_formatter_test.exs")
      |> String.split("\"\"\"")
      |> Enum.drop_every(2)
      |> Enum.join()
      |> String.duplicate(250)

    Benchee.run(%{
      "first attempt" => fn -> TailwindFormatter.format(input, []) end
    })
  end
end
