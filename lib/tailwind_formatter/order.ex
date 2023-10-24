defmodule TailwindFormatter.Order do
  custom_classes = Path.join(Path.dirname(Mix.Project.build_path()), "classes.txt")
  custom_variants = Path.join(Path.dirname(Mix.Project.build_path()), "variants.txt")

  @external_resource custom_classes
  @external_resource custom_variants

  @moduledoc false
  order_map = fn src ->
    Mix.shell().info([:green, "Loading in #{src}."])

    src
    |> File.read!()
    |> String.split(~r/\R/)
    |> Enum.with_index()
    |> Map.new()
  end

  @classes if File.exists?(custom_classes),
             do: order_map.(custom_classes),
             else: order_map.("priv/classes.txt")

  @variants if File.exists?(custom_variants),
              do: order_map.(custom_variants),
              else: order_map.("priv/variants.txt")

  def variants(), do: @variants
  def classes(), do: @classes
end
