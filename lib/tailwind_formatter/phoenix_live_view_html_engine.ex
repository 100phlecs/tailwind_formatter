# Taken directly from Phoenix.LiveView.HTMLEngine
# https://github.com/phoenixframework/phoenix_live_view/blob/v0.20.1/lib/phoenix_live_view/html_engine.ex#L41-L57
defmodule TailwindFormatter.PhoenixLiveViewHTMLEngine do
  @moduledoc false
  def classify_type(":" <> name), do: {:slot, name}
  def classify_type(":inner_block"), do: {:error, "the slot name :inner_block is reserved"}

  def classify_type(<<first, _::binary>> = name) when first in ?A..?Z,
    do: {:remote_component, name}

  def classify_type("." <> name),
    do: {:local_component, name}

  def classify_type(name), do: {:tag, name}

  for void <- ~w(area base br col hr img input link meta param command keygen source) do
    def void?(unquote(void)), do: true
  end

  def void?(_), do: false
end
