defmodule WhatIf.Room do
  use GenServer
  require Logger

  alias WhatIf.User
  alias WhatIf.Repo

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

  def add_question(pid, user_id, question), do: GenServer.call(pid, {:add_question, user_id, question})

  def get_questions(pid), do: GenServer.call(pid, :get_questions)

  def game_started?(pid), do: GenServer.call(pid, :started?)

  def submit_answers(pid, q_and_a, user_id) do
    GenServer.call(pid, {:submit_answers, q_and_a, user_id})
  end

  def persist_and_stop(pid, final_qa) do
    GenServer.call(pid, {:persist, final_qa})
    GenServer.stop(pid)
  end

  ## GenServer callbacks

  @impl true
  def init(name) do
    Logger.info "Starting room #{inspect(name)}"
    {:ok, %__MODULE__{room_name: name}}
  end

  @impl true
  def terminate(:normal, %{room_name: name}) do
    Logger.info "Stopping room #{inspect(name)} (normally)"
    inform_users(name, "Room was deleted")
  end
  def terminate(_reason, %{room_name: name}) do
    Logger.error "Stopping room #{inspect(name)} (abnormally)"
    inform_users(name, "Internal error")
  end

  @impl true
  def handle_call({:submit_answers, q_and_a, user_id}, _from, %{users: users} = state) do
    new_users = users |> Enum.map(fn %{user: user} = entry ->
      case user.user_id do
        ^user_id ->
          %{entry | q_and_a: q_and_a}
        _ -> entry
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
    Logger.info "Adding user #{inspect(user)} to room #{inspect(state.room_name)}"
    new_state = %{state | users: state.users ++ [%{q_and_a: nil, ready?: false, user: user}]}
    {:reply, :ok, new_state}
  end
  def handle_call(:get_name, _from, %{room_name: name} = state), do: {:reply, name, state}
  def handle_call({:delete_user, to_del}, _from, %{users: users} = state) do
    Logger.info "Deleting user #{inspect(to_del)} from room #{inspect(state.room_name)}"
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
    case any_questions_posted?(state) do
      true ->
        Logger.info "Setting user #{inspect(user_id)} ready in room #{inspect(state.room_name)}"
        case all_ready?(new_users) do
          false ->
            {:reply, :ok, %{state | users: new_users}}
          true ->
            {:reply, {:ok, :game_started}, %{state | users: new_users, started?: true}}
        end
      false ->
        Logger.debug "User #{inspect(user_id)} wanted to set ready 
        in room #{inspect(state.room_name)} but no questions are posted"
        {:reply, {:error, :no_questions_added}, state}
    end
  end
  def handle_call({:add_question, user_id, question}, _from, 
                  %{questions: questions, started?: false} = state) do
    Logger.info "Adding question #{inspect(question)} to room #{inspect(state.room_name)}"
    case state.started? do
      false ->
        case user_ready?(user_id, state.users) do
          true ->
            {:reply, {:error, :user_ready}, state}
          false ->
            {:reply, :ok, %{state | questions: questions ++ [question]}}
        end
      true ->
        Logger.warn "... but game has already started"
        {:reply, {:error, :game_already_started}, state}
    end
  end
  def handle_call(:get_questions, _from, %{questions: q} = state), do: {:reply, q, state}
  def handle_call({:persist, final_qa}, _from, %{users: users} = state) do
    Logger.info "Persisting #{inspect(final_qa)}"
    ecto_users = Enum.map(users, fn %{user: user} -> user end)
    game = %{room_name: state.room_name, questions: inspect(final_qa), users: ecto_users}
    changeset = WhatIf.Game.changeset(%WhatIf.Game{}, game)
    Repo.insert!(changeset) 
    {:reply, :ok, state}
  end


  ## Helpers

  defp any_questions_posted?(state) do
    length(state.questions) > 0
  end


  defp user_ready?(user_id, users) do
    [user] = users |> Enum.filter(fn %{user: u} -> user_id == u.user_id end)
    user.ready?
  end

  defp game_finished?(users) do
    users
    |> Enum.all?(fn %{q_and_a: e} -> e !== nil end)
  end

  def get_all_q_and_as(users) do
    users
    |> Enum.map(fn %{q_and_a: a} -> a end)
  end

  # qa: list of lists
  defp mix_qa(qa) do
    qa
    |> transpose()
    |> Enum.map(fn l -> shuffle_answers(l) end)
    |> transpose()
    |> List.flatten()
  end

  defp transpose([]), do: []
  defp transpose([[]|_]), do: []
  defp transpose(a) do
    [Enum.map(a, &hd/1) | transpose(Enum.map(a, &tl/1))]
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
