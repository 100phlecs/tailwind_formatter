import Config

config :esbuild,
  version: "0.17.11",
  module: [
    args: ~w(./index.js --bundle --minify --platform=node --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]
