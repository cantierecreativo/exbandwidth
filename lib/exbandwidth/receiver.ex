defmodule Exbandwidth.Receiver do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: name)
  end
  
  def handle_cast({:traffic, direction, bytes}, state) do
    IO.puts "#{direction}: #{bytes}B/s"
    {:noreply, state}
  end
end
