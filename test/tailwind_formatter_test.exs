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

  test "works" do
    input = """
    <div class="text-sm potato sm:lowercase uppercase"></div>
    """

    expected = """
    <div class="potato text-sm uppercase sm:lowercase"></div>
    """

    assert_formatter_output(input, expected)
  end

  test "handles chained variants" do
    input = """
    <div class="text-sm odd:decoration-slate-50 sm:hover:bg-gray-500 tomato sm:lowercase uppercase sm:hover:bg-unknown-500 disabled:sm:text-lg dark:disabled:sm:lg:group-hover:text-blue-500"></div>
    """

    expected = """
    <div class="tomato text-sm uppercase sm:lowercase sm:hover:bg-unknown-500 sm:hover:bg-gray-500 dark:disabled:sm:lg:group-hover:text-blue-500 odd:decoration-slate-50 disabled:sm:text-lg"></div>
    """

    assert_formatter_output(input, expected)
  end

  test "removes excess whitespace" do
    input = """
    <div class="text-sm     sm:hover:bg-gray-500 tomato     sm:lowercase uppercase sm:hover:bg-unknown-500    disabled:sm:text-lg

    "></div>
    """

    expected = """
    <div class="tomato text-sm uppercase sm:lowercase sm:hover:bg-unknown-500 sm:hover:bg-gray-500 disabled:sm:text-lg"></div>
    """

    assert_formatter_output(input, expected)
  end
end
