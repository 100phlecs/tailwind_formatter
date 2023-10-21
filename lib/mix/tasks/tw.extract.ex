defmodule Mix.Tasks.Tw.Extract do
  use Mix.Task

  @moduledoc """
  Extracts the custom configuration within the local project's tailwind.config.js.

  Requires NodeJS to be on the system.
  """
  def run([]) do
    tw_config_path = Path.absname("assets/tailwind.config.cjs")

    case System.cmd(
           "node",
           [
             Application.app_dir(:tailwind_formatter, "priv/static/assets/index.js"),
             tw_config_path
           ],
           stderr_to_stdout: true
         ) do
      {_stdout, 0} ->
        Mix.shell().info([:green, "Custom configuration extracted."])

      {stdout, err_code} ->
        Mix.shell().error("[ERROR #{err_code}] Couldn't extract custom config. #{stdout}")
    end
  end
end
