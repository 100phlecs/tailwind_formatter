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

  defp assert_formatter_raise(input, dot_formatter_opts \\ []) do
    assert_raise ArgumentError, fn ->
      TailwindFormatter.format(input, dot_formatter_opts)
    end
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

  test "dynamic classes" do
    input = ~S"""
    <a id="testing" class={"  text-sm potato sm:lowercase   grid-cols-#{@test} uppercase"}
      href="#"></a>
    """

    expected = ~S"""
    <a id="testing" class={"grid-cols-#{@test} potato text-sm uppercase sm:lowercase"}
      href="#"></a>
    """

    assert_formatter_output(input, expected)
  end

  test "dynamic varient classes" do
    input = ~S"""
    <a id="testing" class={"  text-sm potato sm:lowercase   lg:grid-cols-#{@test} uppercase"}
      href="#"></a>
    """

    expected = ~S"""
    <a id="testing" class={"potato text-sm uppercase sm:lowercase lg:grid-cols-#{@test}"}
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

  test "allows string concatenation" do
    input = ~S"""
        <div class={"h-6 " <> if @active, do: "bg-white", else: "bg-red"}></div>
    """

    expected = ~S"""
        <div class={"h-6 " <> if @active, do: "bg-white", else: "bg-red"}></div>
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

  test "decimal classes are sorted" do
    input = """
    <div class="text-sm potato unknown1 py-3.5 px-3.5 unknown2 sm:lowercase uppercase"></div>
    """

    expected = """
    <div class="potato unknown1 unknown2 px-3.5 py-3.5 text-sm uppercase sm:lowercase"></div>
    """

    assert_formatter_output(input, expected)
  end

  test "classes with backslash are sorted" do
    input = """
    <div class="text-sm potato unknown1 -inset-1/2 unknown2 sm:lowercase uppercase"></div>
    """

    expected = """
    <div class="potato unknown1 unknown2 -inset-1/2 text-sm uppercase sm:lowercase"></div>
    """

    assert_formatter_output(input, expected)
  end

  test "classes with hash are sorted" do
    input = """
    <div class="text-sm potato bg-[#333] unknown1 unknown2 sm:lowercase uppercase"></div>
    """

    expected = """
    <div class="potato bg-[#333] unknown1 unknown2 text-sm uppercase sm:lowercase"></div>
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

  test "larger css with unknown classes" do
    input = ~S"""
    <a class="bg-colorGreen-400 inline-block rounded-lg px-3 py-3 text-center text-sm font-semibold text-white shadow-sm transition duration-200 hover:bg-colorGreen-500 hover:shadow-md hover:text-lg focus:bg-colorGreen-600 focus:ring-colorGreen-500 focus:shadow-sm focus:ring-4 focus:ring-opacity-50"
      id="testing"
      href="#"></a>
    """

    expected = ~S"""
    <a class="bg-colorGreen-400 inline-block rounded-lg px-3 py-3 text-center text-sm font-semibold text-white shadow-sm transition duration-200 hover:bg-colorGreen-500 hover:text-lg hover:shadow-md focus:bg-colorGreen-600 focus:ring-colorGreen-500 focus:shadow-sm focus:ring-4 focus:ring-opacity-50"
      id="testing"
      href="#"></a>
    """

    assert_formatter_output(input, expected)
  end

  test "larger css with known classes" do
    input = ~S"""
    <a class="bg-green-400 inline-block rounded-lg px-3 py-3 text-center text-sm font-semibold text-white shadow-sm transition duration-200 hover:bg-green-500 hover:shadow-md hover:text-lg focus:bg-green-600 focus:ring-green-500 focus:shadow-sm focus:ring-4 focus:ring-opacity-50"
      id="testing"
      href="#"></a>
    """

    expected = ~S"""
    <a class="inline-block rounded-lg bg-green-400 px-3 py-3 text-center text-sm font-semibold text-white shadow-sm transition duration-200 hover:bg-green-500 hover:text-lg hover:shadow-md focus:bg-green-600 focus:shadow-sm focus:ring-4 focus:ring-green-500 focus:ring-opacity-50"
      id="testing"
      href="#"></a>
    """

    assert_formatter_output(input, expected)
  end

  test "placeholding does not change anything outside of class attr" do
    input = ~S"""
    <a class={"#{if false, do: "bg-white"} text-sm potato sm:lowercase #{isready?(@check)} uppercase"}
      id="testing-#{@id}"
      href="#"></a>
    """

    expected = ~S"""
    <a class={"#{if false, do: "bg-white"} #{isready?(@check)} potato text-sm uppercase sm:lowercase"}
      id="testing-#{@id}"
      href="#"></a>
    """

    assert_formatter_output(input, expected)
  end

  test "can handle multiple interpolated strings" do
    input = ~S"""
    <.img src={~p"/images/#{"card-#{@card.brand}.svg"}"} />
    """

    expected = ~S"""
    <.img src={~p"/images/#{"card-#{@card.brand}.svg"}"} />
    """

    assert_formatter_output(input, expected)
  end

  test "handles classes with placeholders" do
    input = ~S"""
    <tr>
    <th>ETA/ETD</th>
    <td>
    <%= for {vessel, eta, etd} <- list do %>
      <p class={"qa-thingy-etas-#{vessel.id} has-margin-bottom-sm"}>
        <span class={"qa-thingy-etas-#{vessel.id}-vessel"}><%= vessel.name %></span>
        (<span class={"qa-thingy-etas-#{vessel.id}-eta"}><%= convert_date?(
            eta,
            "Not Specified"
          ) %></span> &ndash; <span class={"qa-thingy-etas-#{vessel.id}-etd"}><%= convert_date?(
            etd,
            "Not Specified"
          ) %></span>)
      </p>
    <% end %>
    </td>
    </tr>
    <tr>
    <th>Deliverables</th>
    <td>
    <%= for {fuel, vessel_fuels} <- list,
              vessel_fuel <- vessel_fuels do %>
      <p class={"qa-thingy-deliverable-#{vessel_fuel.id} has-margin-bottom-sm"}>
        <span class="qa-thingy-deliverable-quantity"><%= vessel_fuel.quantity %></span>
        MT of <span class="qa-thingy-deliverable-fuel"><%= fuel.name %></span>
        to
        <span class="qa-thingy-deliverable-vessel">
          <%= vessel_fuel.vessel.name %> (<%= vessel_fuel.vessel.imo %>)
        </span>
      </p>
    <% end %>
    </td>
    </tr>
    """

    expected = ~S"""
    <tr>
    <th>ETA/ETD</th>
    <td>
    <%= for {vessel, eta, etd} <- list do %>
      <p class={"qa-thingy-etas-#{vessel.id} has-margin-bottom-sm"}>
        <span class={"qa-thingy-etas-#{vessel.id}-vessel"}><%= vessel.name %></span>
        (<span class={"qa-thingy-etas-#{vessel.id}-eta"}><%= convert_date?(
            eta,
            "Not Specified"
          ) %></span> &ndash; <span class={"qa-thingy-etas-#{vessel.id}-etd"}><%= convert_date?(
            etd,
            "Not Specified"
          ) %></span>)
      </p>
    <% end %>
    </td>
    </tr>
    <tr>
    <th>Deliverables</th>
    <td>
    <%= for {fuel, vessel_fuels} <- list,
              vessel_fuel <- vessel_fuels do %>
      <p class={"qa-thingy-deliverable-#{vessel_fuel.id} has-margin-bottom-sm"}>
        <span class="qa-thingy-deliverable-quantity"><%= vessel_fuel.quantity %></span>
        MT of <span class="qa-thingy-deliverable-fuel"><%= fuel.name %></span>
        to
        <span class="qa-thingy-deliverable-vessel">
          <%= vessel_fuel.vessel.name %> (<%= vessel_fuel.vessel.imo %>)
        </span>
      </p>
    <% end %>
    </td>
    </tr>
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

    test "custom variant does not flip" do
      input = ~S"""
      <a class=" p-10  mx-auto xs:p-0 md:w-full md:max-w-md"
      id="testing
      href="#"></a>
      """

      expected = ~S"""
      <a class="mx-auto p-10 xs:p-0 md:w-full md:max-w-md"
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

      output = ~S"""
      <a class={"#{if false, do: "bg-white" text-sm potato sm:lowercase uppercase"
        id="testing
        href="#"></a>
      """

      assert_formatter_output(input, output)
    end

    test "invalid elixir fn" do
      input = ~S"""
      <a class={"#{if false, do: } text-sm potato sm:lowercase uppercase"
        id="testing
        href="#"></a>
      """

      assert_formatter_raise(input)
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

    test "works with more than nine string interpolations" do
      input = ~S"""
      <div text={"foo: #{@foo}"} />
      <div text={"foo: #{@foo}"} />
      <div text={"foo: #{@foo}"} />
      <div text={"foo: #{@foo}"} />
      <div text={"foo: #{@foo}"} />
      <div text={"foo: #{@foo}"} />
      <div text={"foo: #{@foo}"} />
      <div text={"foo: #{@foo}"} />
      <div text={"foo: #{@foo}"} />
      <div text={"foo: #{@foo}"} />
      <div text={"foo: #{@foo}"} />

      <div text={"bar: #{@bar}"} />
      <div text={"bar: #{@baz}"} />
      <div text={"bar: #{@barr}"} />
      """

      assert_formatter_output(input, input)
    end
  end
end
