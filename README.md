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

Then run `mix deps.get` and also `mix compile` to load in the plugin.

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

## How it diverges from the original formatter

There are some differences in order to simplify the algorithm.

### Variants are always grouped, even if the class is unknown

i.e. `sm:unknown-class` will still be grouped with the other `sm:` variants, even if Tailwind doesn't recognize the class. 

### Variant order is enforced 

In the original spec, 'variants' i.e. `sm:hover:` are sorted as though it is one block. 
Thus, the order in which they're specified does not matter.
So, for example, a chain of `dark:sm:hover:text-gray-600` would be placed toward the end. 

In this algorithm, classes are sorted by "layers". 
All `sm:` variants are grouped together, even if it's a chain of 4 variants.
So, for example, `dark:sm:hover:text-gray-600` will be placed before any `sm:` and `hover:` variants, because `dark:` has precedence over `sm:` and `hover:`.

Thus, in order to achieve more consistency, the variant chain is ordered.
So, `dark:sm:hover:text-gray-600` transforms to `sm:dark:hover:text-gray-600`.

## Custom classes

As a bonus, this plugin supports the [Phoenix variants](https://fly.io/phoenix-files/phoenix-liveview-tailwind-variants/)
that ship with new applications.

Otherwise, custom classes are not supported at this time. It may be supported in the future.

As this is quite new, there may be some Tailwind classes missing.

## Credits

This project builds heavily off of [rustywind](https://github.com/avencera/rustywind) 
and [HTMLFormatter](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.HTMLFormatter.html).

