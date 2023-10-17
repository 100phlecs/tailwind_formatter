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
    contents
    |> HEExTokenizer.tokenize()
    |> Enum.reduce([], &collect_classes/2)
    |> Enum.reduce(contents, &sort_classes/2)
  end

  defp collect_classes({:tag, _name, attrs, _meta}, acc) do
    case Enum.find(attrs, &(elem(&1, 0) == "class")) do
      {"class", class, _meta} -> [class | acc]
      nil -> acc
    end
  end

  defp collect_classes(_token, acc), do: acc

  defp sort_classes({:string, classes, _meta}, contents),
    do: String.replace(contents, classes, sort(classes))

  defp sort_classes({:expr, expr_class, _meta}, contents) do
    sorted_classes =
      expr_class
      |> Code.string_to_quoted!(literal_encoder: &{:ok, {:__block__, &2, [&1]}})
      |> sort_expr()
      |> Code.quoted_to_algebra()
      |> Inspect.Algebra.format(:infinity)
      |> IO.iodata_to_binary()

    String.replace(contents, expr_class, sorted_classes)
  end

  defp sort_expr({:<<>>, meta, children}), do: {:<<>>, meta, handle_interpolation(children)}
  defp sort_expr({a, b, c}), do: {sort_expr(a), sort_expr(b), sort_expr(c)}
  defp sort_expr({a, b}), do: {sort_expr(a), sort_expr(b)}
  defp sort_expr(list) when is_list(list), do: Enum.map(list, &sort_expr/1)
  defp sort_expr(text) when is_binary(text), do: sort(text)
  defp sort_expr(node), do: node

  defp handle_interpolation(children) do
    {classes_with_placeholders, {placeholder_map, _index}} =
      Enum.map_reduce(children, {%{}, 0}, fn
        str, acc when is_binary(str) ->
          {str, acc}

        node, {placeholder_map, index} ->
          {"#{@placeholder}#{index}#{@placeholder}",
           {Map.put(placeholder_map, "#{index}", node), index + 1}}
      end)

    classes_with_placeholders
    |> Enum.reduce("", fn class, acc ->
      if placeholder?(class) or String.starts_with?(class, "-"),
        do: acc <> class,
        else: "#{acc} #{class}"
    end)
    |> sort()
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

  defp sort_variant_chains(classes) do
    classes
    |> String.split()
    |> Enum.map(&String.split(&1, ":"))
    |> Enum.map(fn chains -> Enum.sort_by(chains, &variant_position/1, :desc) end)
    |> Enum.map(&Enum.join(&1, ":"))
  end

  defp sort(classes) when is_binary(classes) do
    leading_space = if classes =~ ~r/\A\s/, do: " "
    trailing_space = if classes =~ ~r/\s\z/, do: " "

    classes =
      classes
      |> sort_variant_chains()
      |> sort()
      |> Enum.join(" ")

    Enum.join([leading_space, classes, trailing_space])
  end

  defp sort([]), do: []

  defp sort(class_list) when is_list(class_list) do
    {variants, base_classes} = Enum.split_with(class_list, &variant?/1)

    Enum.sort_by(base_classes, &class_position/1) ++ sort_variant_classes(variants)
  end

  defp placeholder?(class), do: String.contains?(class, @placeholder)
  defp variant?(class), do: String.contains?(class, ":")

  defp class_position(class),
    do: if(placeholder?(class), do: -1_000_000, else: Map.get(Order.classes(), class, -1))

  defp variant_position(variant), do: Map.get(Order.variants(), variant, -1)

  defp sort_variant_classes(variants) do
    variants
    |> group_by_first_variant()
    |> Enum.sort_by(fn {variant, _rest} -> variant_position(variant) end)
    |> Enum.map(fn {variant, rest} -> {variant, sort(rest)} end)
    |> Enum.flat_map(fn {variant, rest} -> Enum.map(rest, &"#{variant}:#{&1}") end)
  end

  defp group_by_first_variant(variants) do
    variants
    |> Enum.map(&String.split(&1, ":", parts: 2))
    |> Enum.group_by(&List.first/1, &List.last/1)
  end
end
