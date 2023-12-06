defmodule TailwindFormatter do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias TailwindFormatter.{Order, HEExTokenizer}

  @behaviour Mix.Tasks.Format

  @placeholder "💧"

  def features(_opts) do
    [sigils: [:H], extensions: [".heex"]]
  end

  def format(contents, _opts) do
    class_and_variant_order = Order.class_and_variant_order()

    contents
    |> HEExTokenizer.tokenize()
    |> Enum.reduce([contents], fn
      {:tag, _name, attrs, _meta}, contents ->
        Enum.reduce(attrs, contents, fn
          {"class", class_attr, _meta}, [remainder | acc] ->
            [attr, remainder] = String.split(remainder, old_classes(class_attr), parts: 2)
            [remainder, sort_classes(class_attr, class_and_variant_order), attr | acc]

          _, contents ->
            contents
        end)

      _, contents ->
        contents
    end)
    |> Enum.reverse()
    |> Enum.join()
  end

  defp old_classes({_type, classes, _meta}), do: classes

  defp sort_classes({:string, classes, _meta}, class_and_variant_order),
    do: sort(classes, class_and_variant_order)

  defp sort_classes({:expr, expr_class, _meta}, class_and_variant_order) do
    expr_class
    |> Code.string_to_quoted!(literal_encoder: &{:ok, {:__block__, &2, [&1]}})
    |> sort_expr(class_and_variant_order)
    |> Code.quoted_to_algebra()
    |> Inspect.Algebra.format(:infinity)
    |> IO.iodata_to_binary()
  end

  defp sort_expr({:<<>>, meta, children}, class_and_variant_order),
    do: {:<<>>, meta, handle_interpolation(children, class_and_variant_order)}

  defp sort_expr({a, b, c}, class_and_variant_order),
    do:
      {sort_expr(a, class_and_variant_order), sort_expr(b, class_and_variant_order),
       sort_expr(c, class_and_variant_order)}

  defp sort_expr({a, b}, class_and_variant_order),
    do: {sort_expr(a, class_and_variant_order), sort_expr(b, class_and_variant_order)}

  defp sort_expr(list, class_and_variant_order) when is_list(list),
    do: Enum.map(list, &sort_expr(&1, class_and_variant_order))

  defp sort_expr(text, class_and_variant_order) when is_binary(text),
    do: sort(text, class_and_variant_order)

  defp sort_expr(node, _class_and_variant_order), do: node

  defp handle_interpolation(children, class_and_variant_order) do
    {classes_with_placeholders, {placeholder_map, _index}} =
      Enum.map_reduce(children, {%{}, 0}, fn
        str, acc when is_binary(str) ->
          {str, acc}

        node, {placeholder_map, index} ->
          {"#{@placeholder}#{index}#{@placeholder}",
           {Map.put(placeholder_map, "#{index}", sort_expr(node, class_and_variant_order)),
            index + 1}}
      end)

    classes_with_placeholders
    |> Enum.reduce("", fn class, acc ->
      if placeholder?(class) or String.starts_with?(class, "-"),
        do: acc <> class,
        else: "#{acc} #{class}"
    end)
    |> sort(class_and_variant_order)
    |> String.split()
    |> weave_in_code(placeholder_map)
  end

  defp weave_in_code(classes, placeholder_map) do
    classes
    |> Enum.map(fn class ->
      if placeholder?(class) do
        [prefix, index, suffix] = String.split(class, @placeholder)
        [prefix, Map.fetch!(placeholder_map, index), suffix]
      else
        class
      end
    end)
    |> Enum.intersperse(" ")
    |> List.flatten()
  end

  defp sort_variant_chains(classes, class_and_variant_order) do
    {_class_order, variant_order} = class_and_variant_order

    classes
    |> String.split()
    |> Enum.map(fn class ->
      class
      |> String.split(":")
      |> Enum.sort_by(&variant_position(&1, variant_order), :desc)
      |> Enum.join(":")
    end)
  end

  defp sort(classes, class_and_variant_order) when is_binary(classes) do
    leading_space = if classes =~ ~r/\A\s/, do: " "
    trailing_space = if classes =~ ~r/\s\z/, do: " "

    classes =
      classes
      |> sort_variant_chains(class_and_variant_order)
      |> sort(class_and_variant_order)
      |> Enum.join(" ")

    Enum.join([leading_space, classes, trailing_space])
  end

  defp sort([], _class_and_variant_order), do: []

  defp sort(class_list, class_and_variant_order) when is_list(class_list) do
    {class_order, _variant_order} = class_and_variant_order
    {variants, base_classes} = Enum.split_with(class_list, &variant?/1)

    Enum.sort_by(base_classes, &class_position(&1, class_order)) ++
      sort_variant_classes(variants, class_and_variant_order)
  end

  defp placeholder?(class), do: String.contains?(class, @placeholder)
  defp variant?(class), do: String.contains?(class, ":")
  defp prose?(class), do: String.contains?(class, "prose")

  defp class_position(class, class_order),
    do: if(placeholder?(class), do: -1_000_000, else: Map.get(class_order, class, -1))

  # prose variant order matters, thus push to front
  defp variant_position(variant, variant_order),
    do: if(prose?(variant), do: 0, else: Map.get(variant_order, variant, -1))

  defp sort_variant_classes(variants, class_and_variant_order) do
    {_class_order, variant_order} = class_and_variant_order

    variants
    |> group_by_first_variant()
    |> Enum.sort_by(fn {variant, _rest} -> variant_position(variant, variant_order) end)
    |> Enum.map(fn {variant, rest} -> {variant, sort(rest, class_and_variant_order)} end)
    |> Enum.flat_map(fn {variant, rest} -> Enum.map(rest, &"#{variant}:#{&1}") end)
  end

  defp group_by_first_variant(variants) do
    variants
    |> Enum.map(&String.split(&1, ":", parts: 2))
    |> Enum.group_by(&List.first/1, &List.last/1)
  end
end
