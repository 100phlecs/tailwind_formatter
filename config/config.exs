import Config

if Mix.env() == :dev do
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
end
