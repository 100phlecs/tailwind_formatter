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

  test "supports multiple inline elixir codes" do
    input = ~S"""
    <div class={"#{if false, do: "bg-white"} text-sm potato sm:lowercase #{isready?(@check)} uppercase"}></div>
    """

    expected = ~S"""
    <div class={"#{if false, do: "bg-white"} #{isready?(@check)} potato text-sm uppercase sm:lowercase"}></div>
    """

    assert_formatter_output(input, expected)
  end

  test "supports eex templating code" do
    input = ~S"""
    <%= live_redirect to: Routes.dashboard_path(@socket, :index),
        class: "text-emerald-300 flex-col justify-between flex md:items-center" do %>
        <span class="text-slate-50 p-2 m-2 text-4xl font-semibold">dashboard</span>
    <% end %>
    """

    expected = ~S"""
    <%= live_redirect to: Routes.dashboard_path(@socket, :index),
        class: "flex flex-col justify-between text-emerald-300 md:items-center" do %>
        <span class="m-2 p-2 text-4xl font-semibold text-slate-50">dashboard</span>
    <% end %>
    """

    assert_formatter_output(input, expected)
  end

  test "regex allows multiple attributes" do
    input = ~S"""
    <a id="testing" class={"#{if false, do: "bg-white"} text-sm potato sm:lowercase #{isready?(@check)} uppercase"}
      href="#"></a>
    """

    expected = ~S"""
    <a id="testing" class={"#{if false, do: "bg-white"} #{isready?(@check)} potato text-sm uppercase sm:lowercase"}
      href="#"></a>
    """

    assert_formatter_output(input, expected)
  end

  test "allows comparisons inline elixir" do
    input = ~S"""
    <a id="testing" class={"#{if @page <= 5, do: "bg-white"} text-sm potato sm:lowercase #{isready?(@check)} uppercase"}
      href="#"></a>
    """

    expected = ~S"""
    <a id="testing" class={"#{if @page <= 5, do: "bg-white"} #{isready?(@check)} potato text-sm uppercase sm:lowercase"}
      href="#"></a>
    """

    assert_formatter_output(input, expected)
  end

  test "handles empty classes" do
    input = ~S"""
      <a class=""></a>
      <a class={""} id={"id"}></a>
    """

    expected = ~S"""
      <a class=""></a>
      <a class={""} id={"id"}></a>
    """

    assert_formatter_output(input, expected)
  end

  test "keep consistent format order for unknown classes" do
    input = """
    <div class="text-sm potato unknown1 unknown2 sm:lowercase uppercase"></div>
    """

    expected = """
    <div class="potato unknown1 unknown2 text-sm uppercase sm:lowercase"></div>
    """

    assert_formatter_output(input, expected)
  end

  test "variant ordering keeps prose-* as last variant" do
    input = """
    <div class="prose prose-a:text-sky-600 hover:prose-a:text-sky-300"></div>
    """
    expected = """
    <div class="prose prose-a:text-sky-600 hover:prose-a:text-sky-300"></div>
    """

    assert_formatter_output(input, expected)
  end

  describe "aborts on bad input" do
    test "missing final quote" do
      input = ~S"""
      <a class={"#{if false, do: "bg-white"} text-sm potato sm:lowercase #{isready?(@check)} uppercase
        id="testing 
        href="#"></a>
      """

      expected = ~S"""
      <a class={"#{if false, do: "bg-white"} text-sm potato sm:lowercase #{isready?(@check)} uppercase
        id="testing 
        href="#"></a>
      """

      assert_formatter_output(input, expected)
    end

    test "incomplete inline elixir" do
      input = ~S"""
      <a class={"#{if false, do: "bg-white" text-sm potato sm:lowercase uppercase"
        id="testing 
        href="#"></a>
      """

      expected = ~S"""
      <a class={"#{if false, do: "bg-white" text-sm potato sm:lowercase uppercase"
        id="testing 
        href="#"></a>
      """

      assert_formatter_output(input, expected)
    end

    test "missing number tag inline elixir" do
      input = ~S"""
      <a class={"{if false, do: "bg-white"} text-sm potato sm:lowercase uppercase"}
        id="testing 
        href="#"></a>
      """

      expected = ~S"""
      <a class={"{if false, do: "bg-white"} text-sm potato sm:lowercase uppercase"}
        id="testing 
        href="#"></a>
      """

      assert_formatter_output(input, expected)
    end
  end
end
