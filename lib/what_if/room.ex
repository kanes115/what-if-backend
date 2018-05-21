defmodule WhatIf.Room do
  use GenServer

  @enforce_keys [:name]
  defstruct [:name, {:users, []}]

  def start_link(name) do
    GenServer.start_link(__MODULE__, name)
  end

  @impl true
  def init(name) do
    {:ok, %__MODULE__{name: name}}
  end

  def get_name(pid) do
    GenServer.call(pid, :get_name)
  end

  @impl true
  def handle_call({:add_user, user}, _from, state) do
    new_state = %{state | users: state.users ++ [user]}
    {:reply, :ok, new_state}
  end
  def handle_call(:get_name, _from, %{name: name} = state), do: {:reply, name, state}

  @impl true
  def handle_cast({:push, item}, state) do
    {:noreply, [item | state]}
  end

end
