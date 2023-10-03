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

  defp sort_expr({:<>, meta, children}), do: {:<>, meta, handle_concatenation(children)}
  defp sort_expr({:<<>>, meta, children}), do: {:<<>>, meta, handle_interpolation(children)}
  defp sort_expr({:__block__, meta, [text]}), do: {:__block__, meta, [sort(text)]}
  defp sort_expr(node), do: node

  defp handle_concatenation(children) do
    children
    |> Enum.map(&sort_expr/1)
    |> Enum.map(fn
      {:__block__, meta, [text]} when is_binary(text) ->
        {:__block__, meta, [" #{text} "]}

      node ->
        node
    end)
  end

  defp handle_interpolation(children) do
    {classes, code} =
      children
      |> group_dynamic_prefixes()
      |> Enum.split_with(&is_binary/1)

    {no_prefix, prefixed_code} = Enum.split_with(code, fn {prefix, _node} -> prefix == "" end)

    prefix_map = Map.new(prefixed_code)
    placeholders = Enum.map(Map.keys(prefix_map), &"#{&1}#{@placeholder}")

    sorted_classes =
      (classes ++ placeholders)
      |> Enum.join(" ")
      |> sort()
      |> String.split(@placeholder)
      |> weave_in_prefixed_code(prefix_map)

    pad_interpolations(no_prefix) ++ sorted_classes
  end

  defp weave_in_prefixed_code(class_groups, prefix_map) do
    Enum.flat_map(class_groups, fn class_group ->
      if String.ends_with?(class_group, "-") do
        {rest, dynamic_prefix} = extract_dynamic_prefix(class_group)
        [rest, " #{dynamic_prefix}", Map.fetch!(prefix_map, dynamic_prefix)]
      else
        [class_group]
      end
    end)
  end

  defp group_dynamic_prefixes(children) do
    dynamic_groups = dynamic_classes(children)

    children
    |> Enum.map_reduce("", fn
      node, _acc when is_binary(node) ->
        if node in dynamic_groups, do: extract_dynamic_prefix(node), else: {node, ""}

      node, acc when is_tuple(node) ->
        {{acc, node}, ""}
    end)
    |> then(&elem(&1, 0))
  end

  defp pad_interpolations([]), do: []

  defp pad_interpolations(list),
    do: list |> Enum.map(&elem(&1, 1)) |> Enum.intersperse(" ") |> Enum.concat([" "])

  defp extract_dynamic_prefix(text) do
    [dynamic_prefix | rest] = text |> String.split() |> Enum.reverse()
    {Enum.join(Enum.reverse(rest), " "), dynamic_prefix}
  end

  defp dynamic_classes(children),
    do: Enum.filter(children, fn node -> is_binary(node) and String.ends_with?(node, "-") end)

  defp sort_variant_chains(classes) do
    classes
    |> String.split()
    |> Enum.map(&String.split(&1, ":"))
    |> Enum.map(fn chains -> Enum.sort_by(chains, &variant_position/1, :desc) end)
    |> Enum.map(&Enum.join(&1, ":"))
  end

  defp sort(classes) when is_binary(classes) do
    classes
    |> sort_variant_chains()
    |> sort()
    |> Enum.join(" ")
  end

  defp sort([]), do: []

  defp sort(class_list) do
    {variants, base_classes} = Enum.split_with(class_list, &variant?/1)

    Enum.sort_by(base_classes, &class_position/1) ++ sort_variant_classes(variants)
  end

  defp variant?(class), do: String.contains?(class, ":")
  defp class_position(class), do: Map.get(Order.classes(), class, -1)
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
