# TailwindFormatter

[Online Documentation](https://hexdocs.pm/tailwind_formatter).

<!-- MDOC !-->

Opinionated sorting for [TailwindCSS](https://tailwindcss.com)
classes used in HEEx templates and `~H` sigils.

`TailwindFormatter` is a `mix format` [plugin](https://hexdocs.pm/mix/main/Mix.Tasks.Format.html#module-plugins)
that sorts TailwindCSS classes found in your templates. It takes
inspiration from Tailwind's official [Prettier plugin](https://tailwindcss.com/blog/automatic-class-sorting-with-prettier).

> Note: This formatter requires Elixir v1.15 or later.

## Installation

Add `tailwind_formatter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tailwind_formatter, "~> 0.4.2", only: [:dev, :test], runtime: false}
  ]
end
```

## Setup

`TailwindFormatter` is most likely to be used alongside `Phoenix.LiveView.HTMLFormatter`,
so it should be installed in a way that allows the HTML formatter to
run after the Tailwind formatter. 

Update your `.formatter.exs` to include `TailwindFormatter`.

```elixir
  [
    plugins: [TailwindFormatter, Phoenix.LiveView.HTMLFormatter],
    inputs: [
      "*.{heex,ex,exs}",
      "priv/*/seeds.exs",
      "{config,lib,test}/**/*.{heex,ex,exs}"
    ],
    # ...
  ]
```

## Using Custom TailwindCSS configuration

If you are using the standalone tailwind module, you can append these lines to the end of your `tailwind.config.js` file:

```js
let { extract } = require("../deps/tailwind_formatter/assets/js")
extract(module.exports, "../_build")
```

This will write a `classes.txt` and `variants.txt` to your `_build/` directory. 
The second argument within `extract` may vary depending on the value of `cd:` in your `:tailwind` config. 

The above will work with this configuration, for example:

```elixir
  config :tailwind,
    version: "3.3.3",
    default: [
      args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../_build/assets/out.css
    ),
      cd: Path.expand("../assets", __DIR__)
    ]
```

Run `mix tailwind default` to force it to extract the configuration.

Afterward, when you run `mix compile` you should see TailwindFormatter loading in your custom classes.
If you don't, you can run `mix deps.compile tailwind_formatter --force`.

```bash
❯ mix deps.compile tailwind_formatter --force
==> tailwind_formatter
Compiling 5 files (.ex)
Loading in /path/to/repo/_build/classes.txt.
Loading in /path/to/repo/_build/variants.txt.
Generated tailwind_formatter app
```

## Usage

After installation and setup, run `mix format`. If you already had
automatic formatting set up (for instance, if your editor is configured
to format your code on save), no changes should be required! Your
Tailwind classes should be happily organized going forward!

If some files are not being formatted as expected, double-check the
`:inputs` option in your `.formatter.exs` to ensure they are being
matched.

## Usage in CI

To ensure correct sorting, we ask Tailwind to list its configured clases. We then instantiate this
list at compile-time. Then TailwindFormatter is ready to format, and to check formatting.

In development, all this usually just works due to your existing project setup.

In CI, we have to be a little more explicit. Something like this shown below can be helpful before
running `--check-formatted` if you're getting CI failures about the ordering of CSS classes.

```yaml
- name: Generate classes.txt for tailwind
  run: mix tailwind default

- name: Compile tailwind_formatter plugin
   run: mix deps.compile tailwind_formatter --force

- name: Check code formatting
  run: mix format --check-formatted
```

## Formatting

The formatter aims to follow a bundle of rules outlined in the [blog post](https://tailwindcss.com/blog/automatic-class-sorting-with-prettier)
that introduced the official Tailwind Prettier plugin.

- Order classes the same way they are imported in the CSS file: Base, Components, Utilities
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

### Dynamically rendered classes

Sometimes you may want to dynamically render a class depending on a variable,
i.e. `lg:grid-cols-#{@cols}` or `alert alert-#{@type}`. The formatter supports
this, and also sorts these toward the front of the variant group it is within.

Note: you will need to define the full class either within the Tailwind
[safelist](https://tailwindcss.com/docs/content-configuration#safelisting-classes)
or have it fully written out somewhere else in the source file.

So, for example, if `@cols = 5` within `grid-cols-#{@cols}`, then you will need
`grid-cols-5` written in full somewhere in the source so Tailwind won't purge it
in production.

## Credits

This project builds heavily off of [rustywind](https://github.com/avencera/rustywind)
and [HTMLFormatter](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.HTMLFormatter.html).
