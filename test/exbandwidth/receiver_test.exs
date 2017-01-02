defmodule Exbandwidth.ReceiverTestData do
  def name, do: :receiver_name
end

defmodule Exbandwidth.ReceiverTest do
  use ExUnit.Case, async: false
  import Exbandwidth.ReceiverTestData
  import CaptureChildIO

  setup do
    {:ok, pid} = Exbandwidth.Receiver.start_link(name())

    on_exit fn -> Process.exit(pid, :normal) end

    [receiver_pid: pid]
  end

  describe "start_link/1" do
    test "it names itself with the given name", context do
      pid = Process.whereis(name())

      assert pid == context[:receiver_pid]
    end
  end

  describe "handle_cast/2 - {:traffic, direction, bytes}" do
    test "prints out the supplied value", context do
      output = capture_child_io(
        context[:receiver_pid],
        fn ->
          GenServer.cast context[:receiver_pid], {:traffic, :in, 33}
          Process.sleep(10)
        end)

      assert output == "in: 33B/s\n"
    end
  end
end
