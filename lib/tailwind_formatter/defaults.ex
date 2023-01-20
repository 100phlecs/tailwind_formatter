defmodule TailwindFormatter.Defaults do
  @moduledoc false
  @class_pattern ~r/(?:class\s*(?:=|:)[\s{]*)('|")(.|\s)*?\1}*/i
  @inline_func_pattern ~r/#\{([^}]+)\}*/i
  @dynamic_classes ~r/[[:alnum:]-]*#\{([^}]+)\}*/i
  @invalid_input ~r/[^_a-zA-Z0-9\$\s\-:\[\]\/\.\#]+/

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

  def class_regex() do
    @class_pattern
  end

  def invalid_input_regex() do
    @invalid_input
  end

  def func_regex() do
    @inline_func_pattern
  end

  def dynamic_class_regex() do
    @dynamic_classes
  end

  def class_order() do
    @classes
  end
end
