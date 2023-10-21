defmodule Mix.Tasks.Tw.ExtractTest do
  use ExUnit.Case

  # Get Mix output sent to the current
  # process to avoid polluting tests.
  Mix.shell(Mix.Shell.Process)

  test "successfully extracts" do
    Mix.Tasks.Tw.Extract.run([])

    msg = "Custom configuration extracted."
    assert_received {:mix_shell, :info, [^msg]}
  end
end
