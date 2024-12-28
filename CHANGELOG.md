
# Changelog for v0.4.0

TailwindFormatter v0.4.0 requires Elixir v1.15+.

## Removing TailwindFormatter.MultiFormatter

The above was a stop-gap due to earlier versions of Elixir not supporting multiple formatters in your `.formatter.exs`.

This is no longer the case for Elixir v1.15. Since TailwindFormatter now requires 1.15 and above, this module has been removed.

Your `.formatter.exs` should instead look like this:

```elixir
  [
    plugins: [TailwindFormatter, Phoenix.LiveView.HTMLFormatter],
    # ...
  ]
```

## Support for class lists

TailwindFormatter v0.4.0 now supports class lists like so:

```elixir
    <div
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    />
```

This was achieved by switching our parsing strategy to `Phoenix.LiveView.Tokenizer`.

## Sorting string fragments within elixir expressions

If you have a string fragment with a couple of classes, such as:

```elixir
"#{if true, do: "px-1 bg-white shadow-md"}"
```

the fragment will be sorted as well.

## Custom Tailwind configuration support

Previously TailwindFormatter could only use a dump of default classes and variants from Tailwind. 
Now you can extract your custom classes by injecting two lines into your `tailwind.config.js`.

```js
let { extract } = require("../deps/tailwind_formatter/assets/js")
extract(module.exports, "../_build")
```

This will extract all the classes and variants you are using which TailwindFormatter will use to sort your classes.

## 0.4.1 (2024-12-28)

- Handle remote and local components
- Handle String objects in the custom class js loader
- Documentation touch ups

## 0.4.0 (2023-10-24)

- Bump Elixir version to 1.15
- Remove MultiFormatter as Elixir now supports multiple formatters
- Switch to Phoenix.LiveView.Tokenizer to grab class attributes
- Supports array class lists
- Preserves leading & trailing spaces between expression fragments
- Supports custom TailwindCSS configuration using standalone CLI
