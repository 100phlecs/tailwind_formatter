defmodule TailwindFormatter.Order do
  @external_resource "_build/classes.txt"
  @external_resource "_build/variants.txt"

  @moduledoc false
  order_map = fn src ->
    src
    |> File.read!()
    |> String.split(~r/\R/)
    |> Enum.with_index()
    |> Map.new()
  end

  @classes if File.exists?("_build/classes.txt"),
             do: order_map.("_build/classes.txt"),
             else: order_map.("priv/variants.txt")

  @variants if File.exists?("_build/variants.txt"),
              do: order_map.("_build/variants.txt"),
              else: order_map.("priv/variants.txt")

  def variants(), do: @variants
  def classes(), do: @classes
end
