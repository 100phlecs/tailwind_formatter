defmodule TailwindFormatterTest do
  use ExUnit.Case
  doctest TailwindFormatter

  alias TailwindFormatter

  defp assert_formatter_output(input, expected, dot_formatter_opts \\ []) do
    first_pass = TailwindFormatter.format(input, dot_formatter_opts)
    assert first_pass == expected

    second_pass = TailwindFormatter.format(first_pass, dot_formatter_opts)
    assert second_pass == expected
  end

  def assert_formatter_doesnt_change(code, dot_formatter_opts \\ []) do
    first_pass = TailwindFormatter.format(code, dot_formatter_opts)
    assert first_pass == code

    second_pass = TailwindFormatter.format(first_pass, dot_formatter_opts)
    assert second_pass == code
  end

  test "works without config" do
    input = """
    <div class="text-sm potato sm:lowercase uppercase"></div>
    """

    expected = """
    <div class="potato text-sm uppercase sm:lowercase"></div>
    """

    assert_formatter_output(input, expected)
  end
end
