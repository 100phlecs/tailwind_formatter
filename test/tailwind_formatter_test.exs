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

  test "handles and sorts chained variants" do
    input = """
    <div class="odd:decoration-slate-50 uppercase tomato disabled:sm:text-lg text-sm dark:disabled:sm:lg:group-hover:text-blue-500 sm:lowercase sm:hover:bg-unknown-500 sm:hover:bg-gray-500 sm:disabled:text-2xl"></div>
    """

    expected = """
    <div class="tomato text-sm uppercase odd:decoration-slate-50 sm:lowercase sm:hover:bg-unknown-500 sm:hover:bg-gray-500 sm:disabled:text-lg sm:disabled:text-2xl lg:sm:dark:group-hover:disabled:text-blue-500"></div>
    """

    assert_formatter_output(input, expected)
  end

  test "removes excess whitespace" do
    input = """
    <div class="text-sm     sm:hover:bg-gray-500 tomato     sm:lowercase uppercase sm:hover:bg-unknown-500    sm:disabled:text-lg

    "></div>
    """

    expected = """
    <div class="tomato text-sm uppercase sm:lowercase sm:hover:bg-unknown-500 sm:hover:bg-gray-500 sm:disabled:text-lg"></div>
    """

    assert_formatter_output(input, expected)
  end

  test "supports phx-* variants" do
    input = """
    <div class="phx-click-loading:animate-pulse grow flex shrink disabled:bg-gray-500"></div>
    """

    expected = """
    <div class="flex shrink grow disabled:bg-gray-500 phx-click-loading:animate-pulse"></div>
    """

    assert_formatter_output(input, expected)
  end

  test "supports inline elixir code" do
    input = ~S"""
    <div class={"text-sm #{if false, do: "bg-white"} potato sm:lowercase uppercase"}></div>
    """

    expected = ~S"""
    <div class={"#{if false, do: "bg-white"} potato text-sm uppercase sm:lowercase"}></div>
    """

    assert_formatter_output(input, expected)
  end
end
