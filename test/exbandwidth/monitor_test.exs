defmodule FakeSnmpm do
  use GenServer

  def start_link(replies) do
    GenServer.start_link(__MODULE__, replies, name: :fake_snmpm)
  end

  def sync_get(_user, _agent, _oid_lists) do
    pid = Process.whereis(:fake_snmpm)
    GenServer.call pid, {:get}
  end

  def handle_call({:get}, _from, []) do
    {:noreply, []}
  end
  def handle_call({:get}, from, [:timeout | rest]) do
    GenServer.reply from, {:error, {:timeout, 12345}}
    {:noreply, rest}
  end
  def handle_call({:get}, from, [reply | rest]) do
    GenServer.reply from, {:ok, {1, 2, [{3, 4, 5, reply, 6}]}, 7}
    {:noreply, rest}
  end
end

defmodule FakeReceiver do
  use GenServer

  def start_link(test_pid) do
    GenServer.start_link(__MODULE__, test_pid, name: :receiver)
  end

  def handle_cast({:traffic, direction, bytes}, test_pid) do
    send test_pid, {__MODULE__, :receive, {:traffic, direction, bytes}}
    {:noreply, test_pid}
  end
end

defmodule Exbandwidth.MonitorTestData do
  def if_index, do: 12
  def direction, do: :out
end

defmodule Exbandwidth.MonitorTest do
  use ExUnit.Case, async: true
  import Exbandwidth.MonitorTestData

  setup context do
    {:ok, _snmpm_pid} = FakeSnmpm.start_link(context[:replies])
    {:ok, _receiver_pid} = FakeReceiver.start_link(self())

    {:ok, pid} =
      Exbandwidth.Monitor.start_link({FakeSnmpm}, if_index(), direction())

    on_exit fn -> Process.exit(pid, :normal) end

    [monitor_pid: pid]
  end

  @tag replies: [100, 500]
  test "when the interface exists, it sends the traffic to the receiver" do
    assert_receive {
      FakeReceiver, :receive, {:traffic, direction, bytes}
    }, 3000
    assert direction == Exbandwidth.MonitorTestData.direction
    assert bytes == (500 - 100)
  end

  @tag replies: [:noSuchInstance]
  test "when the interface does not exist, it fails", context do
    Process.flag(:trap_exit, true)

    assert_receive(
      {:EXIT, pid, {error, _location}},
      3000
    )
    assert pid == context[:monitor_pid]
    assert error == %RuntimeError{message: "Unknown interface"}
  end

  @tag replies: [:timeout, 20, 30]
  test "when an SNMP request times out, it carries on" do
    assert_receive {
      FakeReceiver, :receive, {:traffic, direction, bytes}
    }, 4000
    assert direction == Exbandwidth.MonitorTestData.direction
    assert bytes == (30 - 20)
  end
end
