defmodule TailwindFormatter do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias TailwindFormatter.Defaults

  if Version.match?(System.version(), ">= 1.13.0") do
    @behaviour Mix.Tasks.Format
  end

  def features(_opts) do
    [sigils: [:H], extensions: [".heex"]]
  end

  def format(contents, _opts) do
    Regex.replace(Defaults.class_regex(), contents, fn original_str ->
      inline_elixir_functions =
        Regex.scan(Defaults.func_regex(), original_str) |> List.flatten() |> Enum.join(" ")

      classes_only = Regex.replace(Defaults.func_regex(), original_str, "")
      [class_attr, class_val] = String.split(classes_only, ~r/[=:]/, parts: 2)
      needs_curlies = String.match?(class_val, ~r/{/)

      trimmed_classes =
        class_val |> String.trim() |> String.trim("{") |> String.trim("}") |> String.trim("\"") |> String.trim()

      if trimmed_classes == "" || Regex.match?(Defaults.invalid_input_regex(), trimmed_classes) do
        original_str
      else
        sorted_list = trimmed_classes |> String.split() |> sort_variant_chains() |> sort()
        sorted_list = Enum.join([inline_elixir_functions | sorted_list], " ") |> String.trim()
        delimiter = if String.contains?(original_str, "class:"), do: ": ", else: "="

        class_attr <> delimiter <> wrap_classes(sorted_list, needs_curlies)
      end
    end)
  end

  defp wrap_classes(class_list, with_curlies) do
    if with_curlies do
      "{\"" <> class_list <> "\"}"
    else
      "\"" <> class_list <> "\""
    end
  end

  defp sort([]) do
    []
  end

  defp sort(class_list) do
    {base_classes, variants} = separate(class_list)
    base_sorted = sort_base_classes(base_classes)
    variant_sorted = sort_variant_classes(variants)

    base_sorted ++ variant_sorted
  end

  defp sort_base_classes(base_classes) do
    Enum.map(base_classes, fn class ->
      sort_number = Map.get(Defaults.class_order(), class, -1)
      {sort_number, class}
    end)
    |> Enum.sort(&(elem(&1, 0) < elem(&2, 0)))
    |> Enum.map(&elem(&1, 1))
    |> List.flatten()
  end

  defp separate(class_list) do
    class_list
    |> Enum.reduce({[], []}, fn class, tuple ->
      if variant?(class) do
        put_elem(tuple, 1, [class | elem(tuple, 1)])
      else
        put_elem(tuple, 0, [class | elem(tuple, 0)])
      end
    end)
  end

  defp variant?(class) do
    String.contains?(class, ":")
  end

  defp sort_variant_classes(variants) do
    variants
    |> group_by_first_variant()
    |> sort_variant_groups()
    |> sort_classes_per_variant()
    |> grouped_variants_to_list()
  end

  defp sort_variant_chains(variants) do
    variants
    |> Enum.map(&String.split(&1, ":"))
    |> Enum.map(&sort_inverse_variant_order/1)
    |> Enum.map(&Enum.join(&1, ":"))
  end

  defp group_by_first_variant(variants) do
    variants
    |> Enum.map(&String.split(&1, ":", parts: 2))
    |> Enum.group_by(&List.first/1, &List.last/1)
  end

  defp sort_inverse_variant_order(variants) do
    variants
    |> Enum.map(fn variant ->
      sort_number = Map.get(Defaults.variant_order(), variant, -1)
      {sort_number, variant}
    end)
    |> Enum.sort(&(elem(&1, 0) > elem(&2, 0)))
    |> Enum.map(&elem(&1, 1))
  end

  defp sort_variant_groups(variant_groups) do
    variant_groups
    |> Enum.map(fn variant_group ->
      variant = elem(variant_group, 0)
      sort_number = Map.get(Defaults.variant_order(), variant, -1)

      {sort_number, variant_group}
    end)
    |> Enum.sort(&(elem(&1, 0) < elem(&2, 0)))
    |> Enum.map(&elem(&1, 1))
  end

  defp sort_classes_per_variant(grouped_variants) do
    Enum.map(grouped_variants, fn variant_group ->
      {variant, classes_and_variants} = variant_group
      {variant, sort(classes_and_variants)}
    end)
  end

  defp grouped_variants_to_list(grouped_variants) do
    Enum.map(grouped_variants, fn variant_group ->
      {variant, base_classes} = variant_group

      Enum.map(base_classes, fn class ->
        "#{variant}:#{class}"
      end)
    end)
    |> List.flatten()
  end
end
