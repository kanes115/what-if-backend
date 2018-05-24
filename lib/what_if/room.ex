defmodule WhatIf.Room do
  use GenServer

  alias WhatIf.User

  @enforce_keys [:room_name]
  defstruct [:room_name, {:users, []}]

  def start_link(name) do
    GenServer.start_link(__MODULE__, name)
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

  def delete_user(pid, user_id) do
    GenServer.call(pid, {:delete_user, user_id})
  end

  ## GenServer callbacks

  @impl true
  def init(name) do
    {:ok, %__MODULE__{room_name: name}}
  end
  
  @impl true
  def terminate(:normal, %{room_name: name}) do
    inform_users(name, "Room was deleted")
  end
  def terminate(_reason, %{room_name: name}) do
    inform_users(name, "Internal error")
  end

  @impl true
  def handle_call({:add_user, user}, _from, state) do
    new_state = %{state | users: state.users ++ [user]}
    {:reply, :ok, new_state}
  end
  def handle_call(:get_name, _from, %{room_name: name} = state), do: {:reply, name, state}
  def handle_call({:delete_user, to_del}, _from, %{users: users} = state) do
    case user_in_room?(to_del, users) do
      true ->
        remove_room_if_empty(users, %{ state | users: remove_user(to_del, users)})
      false ->
        {:reply, {:error, :not_in_room}, users}
    end
  end

  ## Helpers

  defp remove_room_if_empty([], _), do: {:stop, :normal, nil}
  defp remove_room_if_empty(_, new_state), do: {:reply, :ok, new_state}

  defp remove_user(user_id, users) do
    users
    |> Enum.filter(fn %User{user_id: id} -> id != user_id end)
  end

  defp user_in_room?(user_id, users) do
    user = users
    |> Enum.filter(fn %User{user_id: id} -> id == user_id end)
    case user do
      [] -> false
      _ -> true
    end
  end

  defp inform_users(name, reason) do
    WhatIf.Endpoint.broadcast("room:" <> name, "room_deleted", %{"reason" => reason})
  end

end
