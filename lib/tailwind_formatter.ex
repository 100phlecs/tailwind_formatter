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
    {:ok, contents} = validate_inline_fns(contents)

    {:ok, placeholder_contents, dynamic_classes} = placehold_dynamic_classes(contents)

    sorted_html =
      Regex.replace(Defaults.class_regex(), placeholder_contents, fn class_html_attr ->
        [class_attr, class_val] = String.split(class_html_attr, ~r/[=:]/, parts: 2)
        needs_curlies = String.match?(class_val, ~r/{/)
        maybe_concatenated = String.match?(class_val, ~r/<>/)
        variable_only = not String.match?(class_val, ~r/"/)

        trimmed_classes =
          class_val
          |> String.trim()
          |> String.trim("{")
          |> String.trim("}")
          |> String.trim("\"")
          |> String.trim()

        [trimmed_classes, concatenation] =
          if maybe_concatenated do
            String.split(trimmed_classes, ~r/" <>/)
          else
            [trimmed_classes, ""]
          end

        if variable_only or trimmed_classes == "" or
             Regex.match?(Defaults.invalid_input_regex(), trimmed_classes) do
          class_html_attr
        else
          sorted_list =
            trimmed_classes
            |> String.split()
            |> sort_variant_chains()
            |> sort()
            |> Enum.join(" ")
            |> then(fn sorted ->
              if maybe_concatenated do
                sorted <> " \" <>" <> concatenation
              else
                sorted
              end
            end)

          delimiter = if String.contains?(class_html_attr, "class:"), do: ": ", else: "="

          class_attr <> delimiter <> wrap_classes(sorted_list, needs_curlies)
        end
      end)

    undo_placeholders(sorted_html, dynamic_classes)
  end

  defp validate_inline_fns(contents) do
    Regex.scan(Defaults.func_regex(), contents, capture: :all_but_first)
    |> Enum.map(&List.first/1)
    |> Enum.each(fn elixir_fn ->
      case Code.string_to_quoted(elixir_fn) do
        {:error, {_meta, msg, tok}} ->
          raise ArgumentError, "Invalid inlined elixir function:\n #{elixir_fn} -- #{msg}#{tok}"

        {:ok, _quoted} ->
          :ok
      end
    end)

    {:ok, contents}
  end

  defp placehold_dynamic_classes(contents) do
    dynamic_classes =
      Regex.scan(Defaults.dynamic_class_regex(), contents, capture: :first)
      |> List.flatten()
      |> Enum.with_index()

    placeholder_contents =
      dynamic_classes
      |> Enum.reduce(contents, fn
        {dynamic_class, index}, contents ->
          String.replace(contents, dynamic_class, "$#{index}$")
      end)

    {:ok, placeholder_contents, dynamic_classes}
  end

  defp undo_placeholders(sorted_html, dynamic_classes) do
    dynamic_classes
    |> Enum.reduce(sorted_html, fn
      {dynamic_class, index}, html ->
        String.replace(html, "$#{index}$", dynamic_class)
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
    {variants, base_classes} = separate(class_list)
    base_sorted = sort_base_classes(base_classes)
    variant_sorted = sort_variant_classes(variants)

    base_sorted ++ variant_sorted
  end

  defp separate(class_list) do
    Enum.split_with(class_list, &variant?/1)
  end

  defp variant?(class) do
    String.contains?(class, ":")
  end

  defp placeholder?(class) do
    String.contains?(class, "$")
  end

  defp get_sort_position(class) do
    if placeholder?(class) do
      class
      |> String.trim("$")
      |> String.split("$", parts: 2)
      |> List.first()
      |> String.to_integer()
      # offset to make sure fns are sorted to front
      |> then(fn position -> position - 1_000_000 end)
    else
      Map.get(Defaults.class_order(), class, -1)
    end
  end

  defp sort_base_classes(base_classes) do
    base_classes
    |> Enum.map(fn class ->
      sort_number = get_sort_position(class)
      {sort_number, class}
    end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  defp sort_variant_classes(variants) do
    variants
    |> group_by_first_variant()
    |> sort_variant_groups()
    |> sort_classes_per_variant()
    |> grouped_variants_to_list()
  end

  defp group_by_first_variant(variants) do
    variants
    |> Enum.map(&String.split(&1, ":", parts: 2))
    |> Enum.group_by(&List.first/1, &List.last/1)
  end

  defp sort_variant_groups(variant_groups) do
    variant_groups
    |> Enum.map(fn variant_group ->
      variant = elem(variant_group, 0)
      sort_number = Map.get(Defaults.variant_order(), variant, -1)

      {sort_number, variant_group}
    end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  defp sort_classes_per_variant(grouped_variants) do
    Enum.map(grouped_variants, fn variant_group ->
      {variant, classes_and_variants} = variant_group
      {variant, sort(classes_and_variants)}
    end)
  end

  defp grouped_variants_to_list(grouped_variants) do
    Enum.flat_map(grouped_variants, fn variant_group ->
      {variant, base_classes} = variant_group

      Enum.map(base_classes, fn class ->
        "#{variant}:#{class}"
      end)
    end)
  end

  defp sort_variant_chains(variants) do
    variants
    |> Enum.map(&String.split(&1, ":"))
    |> Enum.map(&sort_inverse_variant_order/1)
    |> Enum.map(&Enum.join(&1, ":"))
  end

  defp sort_inverse_variant_order(variants) do
    variants
    |> Enum.map(fn variant ->
      sort_number = Map.get(Defaults.variant_order(), variant, -1)
      {sort_number, variant}
    end)
    |> Enum.sort_by(&elem(&1, 0), :desc)
    |> Enum.map(&elem(&1, 1))
  end
end
