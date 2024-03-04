defmodule TailwindFormatter.Order do
  def class_and_variant_order do
    custom_classes = Path.join(Path.dirname(Mix.Project.build_path()), "classes.txt")
    custom_variants = Path.join(Path.dirname(Mix.Project.build_path()), "variants.txt")

    classes =
      if File.exists?(custom_classes),
        do: order_map(custom_classes),
        else: order_map("priv/classes.txt")

    variants =
      if File.exists?(custom_variants),
        do: order_map(custom_variants),
        else: order_map("priv/variants.txt")

    {classes, variants}
  end

  defp order_map(src) do
    src
    |> File.read!()
    |> String.split(~r/\R/)
    |> Enum.with_index()
    |> Map.new()
  end
end
