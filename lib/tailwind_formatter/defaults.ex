defmodule TailwindFormatter.Defaults do
  @moduledoc false

  ## pattern ~r/\b(?:class(?:Name)*\s*(=|:)\s*["'])([_a-zA\.-Z0-9\s\-:\[\]]+)["']/i
  @pattern ~r/\b(?:class(?:Name)*\s*(?:=|:)\s*{*\s*["'])((?:[_a-zA\.-Z0-9\s\-:\[\]]+)(#\{[^}]+\}*)*(?:[_a-zA\.-Z0-9\s\-:\[\]]+))["']+\s*\}*/i

  @variants "priv/variants.txt"
            |> File.read!()
            |> String.split(~r/\R/)
            |> Enum.with_index()
            |> Map.new()

  @classes "priv/classes.txt"
           |> File.read!()
           |> String.split(~r/\R/)
           |> Enum.with_index()
           |> Map.new()

  def variant_order() do
    @variants
  end

  def regex_pattern() do
    @pattern
  end

  def class_order() do
    @classes
  end
end
