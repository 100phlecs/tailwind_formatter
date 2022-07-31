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
    Regex.replace(Defaults.regex_pattern(), contents, fn original, _split, classes ->
      class_list = String.split(classes)
      sorted_list = sort(class_list) |> Enum.join(" ")

      String.replace(original, ~r/"([^"]*)"/, "\"" <> sorted_list <> "\"")
    end)
  end

  defp sort([]) do
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
    |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
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
    |> group_by_variant()
    |> sort_by_variant_order()
    |> sort_classes_per_variant()
    |> grouped_variants_to_list()
  end

  defp group_by_variant(variants) do
    variants
    |> Enum.map(&String.split(&1, ":", parts: 2))
    |> Enum.group_by(&List.first/1, &List.last/1)
  end

  defp sort_by_variant_order(variant_groups) do
    variant_groups
    |> Enum.map(fn variant_group ->
      variant = elem(variant_group, 0)
      sort_number = Map.get(Defaults.variant_order(), variant, -1)

      {sort_number, variant_group}
    end)
    |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
    |> Enum.map(&elem(&1, 1))
  end

  defp sort_classes_per_variant(grouped_variants) do
    Enum.map(grouped_variants, fn variant_group ->
      {variant, base_classes} = variant_group
      {variant, sort(base_classes)}
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
