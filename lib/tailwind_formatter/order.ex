defmodule TailwindFormatter.Order do
  dir =
    Application.compile_env(
      :tailwind_formatter,
      :custom_file_dir,
      Path.dirname(Mix.Project.build_path())
    )

  @dir dir

  @file_hash Path.wildcard(Path.join(dir, "*.txt"))
             |> :erlang.md5()

  custom_classes = Path.join(dir, "classes.txt")
  custom_variants = Path.join(dir, "variants.txt")

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

  def __mix_recompile__? do
   Path.wildcard(Path.join(@dir, "*.txt")) |> :erlang.md5() != @file_hash
  end
end
