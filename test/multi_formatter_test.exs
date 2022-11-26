defmodule MultiFormatterTest do
  use ExUnit.Case

  alias TailwindFormatter.MultiFormatter

  defp assert_formatter_output(input, expected, dot_formatter_opts \\ []) do
    first_pass = MultiFormatter.format(input, dot_formatter_opts)
    assert first_pass == expected

    second_pass = MultiFormatter.format(first_pass, dot_formatter_opts)
    assert second_pass == expected
  end

  test "multiformat works" do
    input = """
    <div class="text-sm potato sm:lowercase uppercase">


    </div>
    """

    expected = """
    <div class="potato text-sm uppercase sm:lowercase"></div>
    """

    assert_formatter_output(input, expected)
  end
end
