defmodule WhatIf.Room do
  use GenServer

  @enforce_keys [:room_name]
  defstruct [:room_name, {:users, []}]

  def start_link(name) do
    GenServer.start_link(__MODULE__, name)
  end

  @impl true
  def init(name) do
    {:ok, %__MODULE__{room_name: name}}
  end

  def get_name(pid) do
    GenServer.call(pid, :get_name)
  end

  def delete_room(pid) do
    GenServer.stop(pid, :normal)
  end

  def add_user(pid, user) do
    GenServer.call(pid, {:add_user, user})
  end

  @impl true
  def terminate(normal, _) do
    :ok
  end

  @impl true
  def handle_call({:add_user, user}, _from, state) do
    new_state = %{state | users: state.users ++ [user]}
    {:reply, :ok, new_state}
  end
  def handle_call(:get_name, _from, %{room_name: name} = state), do: {:reply, name, state}

  @impl true
  def handle_cast({:push, item}, state) do
    {:noreply, [item | state]}
  end

end
