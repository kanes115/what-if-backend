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

  def game_started?(pid), do: GenServer.call(pid, :started?)

  def submit_answers(pid, q_and_a, user_id) do
    GenServer.call(pid, {:submit_answers, q_and_a, user_id})
  end

  ## GenServer callbacks

  @impl true
  def init(name) do
    IO.inspect "Starting room #{inspect(name)}"
    {:ok, %__MODULE__{room_name: name}}
  end

  @impl true
  def terminate(:normal, %{room_name: name}) do
    IO.inspect "Stopping room #{inspect(name)} (normally)"
    inform_users(name, "Room was deleted")
  end
  def terminate(_reason, %{room_name: name}) do
    IO.inspect "Stopping room #{inspect(name)} (abnormally)"
    inform_users(name, "Internal error")
  end

  @impl true
  def handle_call({:submit_answers, q_and_a, user_id}, _from, %{users: users} = state) do
    new_users = users |> Enum.map(fn %{user: user} = entry ->
      case user.user_id do
        ^user_id ->
          %{entry | q_and_a: q_and_a}
        e -> entry
      end
    end)
    case game_finished?(new_users) do
      false ->
        {:reply, {:ok, :game_not_finished}, %{state | users: new_users}}
      true ->
        all_qa = get_all_q_and_as(new_users)
        {:reply, {:ok, :game_finished, mix_qa(all_qa)}, %{state | users: new_users}}
    end
  end
  def handle_call(:started?, _from, state) do
    {:reply, state.started?, state}
  end
  def handle_call({:add_user, user}, _from, state) do
    IO.inspect "Adding user #{inspect(user)} to room #{inspect(state.room_name)}"
    new_state = %{state | users: state.users ++ [%{q_and_a: nil, ready?: false, user: user}]}
    {:reply, :ok, new_state}
  end
  def handle_call(:get_name, _from, %{room_name: name} = state), do: {:reply, name, state}
  def handle_call({:delete_user, to_del}, _from, %{users: users} = state) do
    IO.inspect "Deleting user #{inspect(to_del)} from room #{inspect(state.room_name)}"
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
    IO.inspect "Setting user #{inspect(user_id)} ready in room #{inspect(state.room_name)}"
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
  def handle_call({:add_question, question}, _from, 
                  %{questions: questions, started?: false} = state) do
    IO.inspect "Adding question #{inspect(question)} to room #{inspect(state.room_name)}"
    case state.started? do
      false ->
        {:reply, :ok, %{state | questions: questions ++ [question]}}
      true ->
        IO.inspect "... but game has already started"
        {:reply, {:error, :game_already_started}, state}
    end
  end
  def handle_call(:get_questions, _from, %{questions: q} = state), do: {:reply, q, state}

  ## Helpers
  #
  defp game_finished?(users) do
    users
    |> Enum.all?(fn %{q_and_a: e} -> e !== nil end)
  end

  def get_all_q_and_as(users) do
    users
    |> Enum.map(fn %{q_and_a: a} -> a end)
  end

  # qa: list of lists
  defp mix_qa([head | _] = qa) do
    IO.inspect qa
    a = for x <- 0..length(head) - 1, do: Enum.map(qa, fn l -> Enum.at(l, x) end) 
    b = a |> Enum.map(fn l -> shuffle_answers(l) end)
    res = for x <- 0..length(qa) - 1, do: Enum.map(b, fn l -> Enum.at(l, x) end) 
    res
    |> List.flatten()
  end

  defp shuffle_answers(qas) do
    q = qas
        |> Enum.map(fn %{"question" => q} -> q end)
    a = qas
        |> Enum.map(fn %{"answer" => a} -> a end)
        |> Enum.shuffle()
    q
    |> Enum.zip(a)
    |> Enum.map(fn {q, a} -> %{"question" => q, "answer" => a} end)
  end


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
