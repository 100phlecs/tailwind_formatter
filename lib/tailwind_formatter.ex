defmodule TailwindFormatter do
  @moduledoc """
  Documentation for `TailwindFormatter`.
  """
  alias TailwindFormatter.Defaults

  if Version.match?(System.version(), ">= 1.13.0") do
    @behaviour Mix.Tasks.Format
  end

  def features(_opts) do
    [sigils: [:H], extensions: [".heex"]]
  end

  def format(contents, _opts) do
    Regex.replace(Defaults.regex_pattern(), contents, fn original, _split, classes ->
      {base_classes, variants} = separate(classes)

      base_sorted = sort_base_classes(base_classes) |> Enum.join(" ")

      variant_sorted =
        Enum.map(variants, fn variant_class ->
          String.split(variant_class, ":")
        end)
        |> Enum.group_by(&List.first/1, &List.last/1)
        |> Map.to_list()
        |> sort_variant_groups
        |> Enum.map(fn variant_group ->
          {variant, base_classes} = variant_group

          sorted_classes = sort_base_classes(base_classes)

          Enum.map(sorted_classes, fn class ->
            "#{variant}:#{class}"
          end)
          |> Enum.join(" ")
        end)
        |> Enum.join(" ")

      sorted_classes =
        (base_sorted <> " " <> variant_sorted)
        |> String.trim()

      String.replace(original, ~r/"([^"]*)"/, "\"" <> sorted_classes <> "\"")
    end)
  end

  defp sort_variant_groups(variant_groups) do
    Enum.map(variant_groups, fn variant_group ->
      {Map.get(Defaults.variant_order(), elem(variant_group, 0), -1), variant_group}
    end)
    |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
    |> Enum.map(&elem(&1, 1))
  end

  defp sort_base_classes(base_classes) do
    Enum.map(base_classes, fn class ->
      {Map.get(Defaults.class_order(), class, -1), class}
    end)
    |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
    |> Enum.map(&elem(&1, 1))
    |> List.flatten()
  end

  defp separate(classes) do
    classes
    |> String.split(" ")
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
end
