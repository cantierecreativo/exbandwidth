defmodule Exbandwidth.Monitor do
  # http://oid-info.com/get/1.3.6.1.2.1.2.2.1
  @ifentry_oid [
    1, # iso
    3, # identified-orgaization
    6, # dod
    1, # internet
    2, # mgmt
    1, # mib-2 - http://www.ietf.org/rfc/rfc1213.txt
    2, # interface
    2, # ifTable
    1  # ifEntry
  ]
  @if_octets_oids [in: 10, out: 16]

  def start_link({snmpm}, if_index, direction) do
    state = {snmpm, if_index, direction, nil}
    pid = spawn_link(fn -> loop(state) end)
    {:ok, pid}
  end

  defp loop({snmpm, if_index, direction, previous}) do
    counter_oid = @if_octets_oids[direction]
    :timer.sleep(1000)

    call(snmpm, counter_oid, if_index)
    |> extract_result
    |> handle_result({snmpm, if_index, direction, previous})
  end

  defp call(snmpm, counter_oid, if_index) do
    oids = @ifentry_oid ++ [counter_oid, if_index]
    snmpm.sync_get('default_user', 'default_agent', [oids])
  end

  defp extract_result({:error, {:timeout, _t}}) do
    :timeout
  end
  defp extract_result({:ok, answer, _}) do
    {_, _, [{_, _, _, result, _}]} = answer
    result
  end

  defp handle_result(:noSuchInstance, _state) do
    raise "Unknown interface"
  end
  defp handle_result(:timeout, {snmpm, if_index, direction, previous}) do
    loop({snmpm, if_index, direction, previous})
  end
  defp handle_result(result, {snmpm, if_index, direction, nil}) do
    loop({snmpm, if_index, direction, result})
  end
  defp handle_result(result, {snmpm, if_index, direction, previous}) do
    change = result - previous
    receiver_pid = Process.whereis(:receiver)
    GenServer.cast receiver_pid, {:traffic, direction, change}

    loop({snmpm, if_index, direction, result})
  end
end
