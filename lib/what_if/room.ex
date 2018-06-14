defmodule WhatIf.Room do
  use GenServer

  alias WhatIf.User

  @enforce_keys [:room_name]
  defstruct [:room_name, {:users, []}, {:questions, []}, {:started?, false}]

  def start_link(name) do
    GenServer.start_link(__MODULE__, name)
  end

  def get_name(pid), do: GenServer.call(pid, :get_name)

  def delete_room(pid), do: GenServer.stop(pid, :normal)

  def add_user(pid, user), do: GenServer.call(pid, {:add_user, user})

  def set_user_ready(pid, user_id), do: GenServer.call(pid, {:set_user_ready, user_id})

  def delete_user(pid, user_id), do: GenServer.call(pid, {:delete_user, user_id})

  def get_users(pid), do: GenServer.call(pid, :get_users)

  def add_question(pid, question), do: GenServer.call(pid, {:add_question, question})

  def get_questions(pid), do: GenServer.call(pid, :get_questions)

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
    new_state = %{state | users: state.users ++ [%{ready?: false, user: user}]}
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
  def handle_call(:get_users, _from, %{users: users} = state) do
    users_names = users |> Enum.map(fn %{ready?: ready?, user: u} ->
      %{"user" => u.display_name, "user_id" => u.user_id, "ready" => ready?} end)
    {:reply, users_names, state}
  end
  def handle_call({:set_user_ready, user_id}, _from, %{users: users, started?: false} = state) do
    new_users = users |> Enum.map(fn %{user: %{user_id: ^user_id}} = entry -> 
      %{entry | ready?: true}
      u -> u end)
    case all_ready?(new_users) do
      false ->
        {:reply, :ok, %{state | users: new_users}}
      true ->
        {:reply, {:ok, :game_started}, %{state | users: new_users, started?: true}}
    end
  end
  def handle_call({:add_question, question}, _from, %{questions: questions, started?: false} = state) do
    case state.started? do
      false ->
        {:reply, :ok, %{state | questions: questions ++ [question]}}
      true ->
        {:reply, {:error, :game_already_started}, state}
    end
  end
  def handle_call(:get_questions, _from, %{questions: q} = state), do: {:reply, q, state}

  ## Helpers

  defp remove_room_if_empty([], _), do: {:stop, :normal, nil}
  defp remove_room_if_empty(_, new_state), do: {:reply, :ok, new_state}

  defp all_ready?(users) do
    users |> Enum.all?(fn u -> u.ready? end)
  end

  defp remove_user(user_id, users) do
    users
    |> Enum.filter(fn %{user: %User{user_id: id}} -> id != user_id end)
  end

  defp user_in_room?(user_id, users) do
    user = users
           |> Enum.filter(fn %{user: %User{user_id: id}} -> id == user_id end)
    case user do
      [] -> false
      _ -> true
    end
  end

  defp inform_users(name, reason) do
    WhatIf.Endpoint.broadcast("room:" <> name, "room_deleted", %{"reason" => reason})
  end

end
