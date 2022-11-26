# TailwindFormatter

[Online Documentation](https://hexdocs.pm/tailwind_formatter).

<!-- MDOC !-->

Enforce a `class` attribute order within markup using [TailwindCSS](tailwindcss.com). 

this is a `mix format` [plugin](https://hexdocs.pm/mix/main/Mix.Tasks.Format.html#module-plugins).

> Note: The Tailwind Formatter requires Elixir v1.13.4 or later

## Installation

Add `tailwind_formatter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tailwind_formatter, "~> 0.3.0"}

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

Then run `mix deps.get` and also `mix compile` to load in the plugin.

After that, run the formatter with `mix format`.

Note: If you're using multiple formatters and you're running an Elixir
version that supports multiple format plugins, keep in mind that the
order by which the plugins are defined in the `plugins: []` array are
the order in which they are ran.

### Setup multiple formatters for older versions 

If you plan to use this with another formatter, you may run into issues.
Thie is because `mix format`, depending on your version, may not support multiple
plugins ([just yet](https://github.com/elixir-lang/elixir/pull/12032))!

There are two options to work around this. The first option is, if you
are formatting with `Phoenix.LiveView.HTMLFormatter`, to use the
`MultiFormatter` shipped with this library instead of
`TailwindFormatter`.

The `MultiFormatter` will first format with `HTMLFormatter` and then
follow up with `TailwindFormatter`.

The other option is to set up two `.formatter.exs` files and a script
within your base directory, i.e. `format.sh` which runs both.

In `format.sh`:

```bash
#!/usr/bin/env bash
mix format --dot-formatter .tailwind_formatter.exs
mix format # this runs the default .formatter.exs
```

And then `chmod +x format.sh`.

## Formatting

The formatter aims to follow a bundle of rules outlined in the [blog post](https://tailwindcss.com/blog/automatic-class-sorting-with-prettier)
that introduces the official Tailwind sorter plugin. 

- Order them the same way classes are imported in the CSS file. Base, Components, Utilities.
- Classes that override other classes appear later in the list
- Classes that impact layout take precedence over classes that decorate 
- Plain classes come first before variants (i.e. `focus:`)
- Unknown classes are sorted to the front

## How it diverges from the original formatter

There are some differences in order to simplify the algorithm and to support Elixir use cases.

### Inline elixir functions are sorted toward the front

With elixir templating one may add an `#{inline_elixir_function}` to the class list.
The formatter supports this and sorts these toward the front.

### Variants are always grouped, even if the class is unknown

i.e. `sm:unknown-class` will still be grouped with the other `sm:` variants, even if Tailwind doesn't recognize the class. 

### Variant order is enforced 

In the original spec, 'variants' i.e. `sm:hover:` are sorted as though it is one block. 
Thus, the order in which they're specified does not matter.
So, for example, a chain of `dark:sm:hover:text-gray-600` would be placed toward the end. 

In this algorithm, classes are sorted by "layers". 
All `sm:` variants are grouped together, even if it's a chain of 4 variants.
So for example, `dark:sm:hover:text-gray-600` will be placed before any `sm:` and `hover:` variants, because `dark:` has precedence over `sm:` and `hover:`.

Thus in order to achieve more consistency, the variant chain is ordered.
So, `dark:sm:hover:text-gray-600` transforms to `sm:dark:hover:text-gray-600`.

## Custom classes

As a bonus this plugin supports the [Phoenix variants](https://fly.io/phoenix-files/phoenix-liveview-tailwind-variants/)
that ship with new applications.

Otherwise custom classes are not supported at this time. It may be supported in the future.

As this is quite new there may be some Tailwind classes missing.

## Credits

This project builds heavily off of [rustywind](https://github.com/avencera/rustywind) 
and [HTMLFormatter](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.HTMLFormatter.html).

