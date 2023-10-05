defmodule TailwindFormatter.Order do
  @moduledoc false

  @default_variants "priv/variants.txt"
                    |> File.read!()
                    |> String.split(~r/\R/)
                    |> Enum.with_index()
                    |> Map.new()

  @default_classes "priv/classes.txt"
                   |> File.read!()
                   |> String.split(~r/\R/)
                   |> Enum.with_index()
                   |> Map.new()

  def variants() do
    @default_variants
  end

  def classes() do
    @default_classes
  end
end
