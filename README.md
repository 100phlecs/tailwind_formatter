# TailwindFormatter

[Online Documentation](https://hexdocs.pm/tailwind_formatter).

<!-- MDOC !-->

Enforce a `class` attribute order with templates using [TailwindCSS](tailwindcss.com). 

## Installation

Add `tailwind_formatter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tailwind_formatter, "~> 0.1.0"}

    # alternatively, keep track with the latest release:
    {:tailwind_formatter, github: "100phlecs/tailwind_formatter"}
  ]
end
```

## Setup

Add it as a plugin to your project's `.formatter.exs`. 
Make sure to put in the `heex` extension to the possible inputs.

```elixir
  [
    plugins: [TailwindFormatter],
    inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}"
    ],
  ]
```

Make sure to run `mix deps.get` and also `mix compile` to load in the plugin.

After that, run the formatter with `mix format`.

If using different formatters on the template, it is suggested 
to list `TailwindFormatter` as the first extension.

## Formatting

The formatter aims to follow a bundle of rules outlined in the [blog post](https://tailwindcss.com/blog/automatic-class-sorting-with-prettier)
that introduces the official Tailwind sorter plugin. 

- Order them the same way classes are imported in the CSS file. Base, Components, Utilities.
- Classes that override other classes appear later in the list
- Classes that impact layout take precedence over classes that decorate 
- Plain classes come first before variants (i.e. `focus:`)
- Unknown classes are sorted to the front


As a bonus, this plugin supports the [Phoenix variants](https://fly.io/phoenix-files/phoenix-liveview-tailwind-variants/)
that ship with new applications.

As this is quite new, there may be some new Tailwind classes missing.


## Credits

This project builds heavily off of [rustywind](https://github.com/avencera/rustywind) 
and [HTMLFormatter](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.HTMLFormatter.html).

