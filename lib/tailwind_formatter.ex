defmodule TailwindFormatter do
  @moduledoc """
  Documentation for `TailwindFormatter`.
  """

  @behaviour Mix.Tasks.Format

  @impl Mix.Tasks.Format
  def features(_opts) do
    [sigils: [:H], extensions: [".heex"]]
  end

  @impl Mix.Tasks.Format
  def format(contents, opts) do
    run(:default, [contents])
  end


  @doc """
  Returns the path to the executable.
  The executable may not be available if it was not yet installed.
  """
  def bin_path do
    name = "tailwindsort-#{target()}"

    Application.get_env(:tailwindsort, :path) ||
      if Code.ensure_loaded?(Mix.Project) do
        Path.join(Path.dirname(Mix.Project.build_path()), name)
      else
        Path.expand("_build/#{name}")
      end
  end

  @doc """
  Runs the given command with `args`.
  The given args will be appended to the configured args.
  """
  def run(profile, extra_args) when is_atom(profile) and is_list(extra_args) do
    config = [] # config_for!(profile)
    args = config[:args] || ["--config", "assets/tailwind.config.js"]

    opts = [
      cd: config[:cd] || File.cwd!(),
      env: config[:env] || %{},
      stderr_to_stdout: true
    ]
    
    IO.inspect(bin_path())
    IO.inspect(File.cwd!())
    result = bin_path()
    |> System.cmd(args ++ extra_args, opts)
    IO.inspect(result)
    elem(result, 0)
  end

  # Available targets:
  #  tailwindsort-linux-arm64
  #  tailwindsort-linux-x64
  #  tailwindsort-macos-arm64
  #  tailwindsort-macos-x64
  #  tailwindsort-windows-x64.exe
  defp target do
    arch_str = :erlang.system_info(:system_architecture)
    [arch | _] = arch_str |> List.to_string() |> String.split("-")

    case {:os.type(), arch, :erlang.system_info(:wordsize) * 8} do
      {{:win32, _}, _arch, 64} -> "windows-x64.exe"
      {{:unix, :darwin}, arch, 64} when arch in ~w(arm aarch64) -> "macos-arm64"
      {{:unix, :darwin}, "x86_64", 64} -> "macos-x64"
      {{:unix, :linux}, "aarch64", 64} -> "linux-arm64"
      {{:unix, _osname}, arch, 64} when arch in ~w(x86_64 amd64) -> "linux-x64"
      {_os, _arch, _wordsize} -> raise "tailwind is not available for architecture: #{arch_str}"
    end
  end
end

