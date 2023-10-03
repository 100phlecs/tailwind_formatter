defmodule TailwindFormatter.HEExTokenizer do
  @moduledoc false
  alias Phoenix.LiveView.Tokenizer

  # Taken directly from Phoenix.LiveView.HTMLFormatter
  @eex_expr [:start_expr, :expr, :end_expr, :middle_expr]
  def tokenize(source) do
    {:ok, eex_nodes} = EEx.tokenize(source)
    {tokens, cont, true} = Enum.reduce(eex_nodes, {[], :text}, &do_tokenize(&1, &2, source))
    Tokenizer.finalize(tokens, "nofile", cont, source)
  end

  defp do_tokenize({:text, text, meta}, {tokens, cont}, source) do
    text = List.to_string(text)
    meta = [line: meta.line, column: meta.column]
    state = Tokenizer.init(0, "nofile", source, Phoenix.LiveView.HTMLEngine)
    Tokenizer.tokenize(text, meta, tokens, cont, state)
  end

  defp do_tokenize({:comment, text, meta}, {tokens, cont}, _contents) do
    {[{:eex_comment, List.to_string(text), meta} | tokens], cont}
  end

  defp do_tokenize({type, opt, expr, %{column: column, line: line}}, {tokens, cont}, _contents)
       when type in @eex_expr do
    meta = %{opt: opt, line: line, column: column}
    {[{:eex, type, expr |> List.to_string() |> String.trim(), meta} | tokens], cont}
  end

  defp do_tokenize(_node, acc, _contents) do
    acc
  end
end
