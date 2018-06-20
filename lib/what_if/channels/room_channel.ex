defmodule WhatIf.RoomChannel do
  use Phoenix.Channel

  alias WhatIf.User
  alias WhatIf.Room
  alias WhatIf.RoomsManager

  def join("room:" <> room_name = topic, _message, socket) do
    user_id = socket.assigns.user_id
    user = User.get_user_by_id(user_id)
    case {can_join?(user), RoomsManager.get_room_by_name(room_name)} do
      {{false, reason}, _} ->
        {:error, %{reason: reason}}
      {_, {:error, reason}} ->
        {:error, %{reason: reason}}
      {true, {:ok, pid}} ->
        Room.add_user(pid, user)
        WhatIf.Endpoint.broadcast(topic, "user_joined", %{"user" => user.display_name,
                                                          "user_id" => user.user_id})
        {:ok, socket}
    end
    {:ok, socket}
  end

  def terminate({:shutdown, :left}, socket) do
    maybe_room = socket
           |> get_room_pid() 
    case maybe_room do
      {:error, reason} -> 
        IO.puts "Tried to remove user from room but it already did not exist"
        IO.inspect reason
        # This whole clause probably unnecessary but let's log if this
        # situation happens ever
        :ok
      room ->
        user_id = socket.assigns.user_id
        joined_user = User.get_user_by_id(user_id)
        Room.delete_user(room, user_id)
        broadcast! socket, "user_left", %{"user_id" => joined_user.user_id}
        {:noreply, socket}
    end
  end
  def terminate({:shutdown, :closed}, socket) do
    {:noreply, socket}
  end

  def handle_in("get_users", %{}, socket) do
    {:ok, room} = socket
                  |> get_room_name()
                  |> RoomsManager.get_room_by_name()
    push socket, "user_list", %{"users" => Room.get_users(room)}
    {:noreply, socket}
  end
  def handle_in("ready", %{}, socket) do
    user_id = socket.assigns.user_id
    user = User.get_user_by_id(user_id)
    res = socket 
    |> get_room_pid() 
    |> Room.set_user_ready(user_id)
    case res do
      :ok ->
        broadcast! socket, "ready", %{"user_id" => user.user_id,
                                      "game_started" => false}
      {:ok, :game_started} ->
        broadcast! socket, "ready", %{"user_id" => user.user_id,
                                      "game_started" => true}
    end
    {:noreply, socket}
  end
  def handle_in("add_question", %{"question" => question} = body, socket) do
    user_id = socket.assigns.user_id
    res = socket
    |> get_room_pid() 
    |> Room.add_question(user_id, question)
    case res do
      {:error, reason} ->
        push socket, "error", %{"reason" => reason_to_msg(reason)}
      _ ->
        broadcast! socket, "new_question", body
    end
    {:noreply, socket}
  end
  def handle_in("get_questions", %{}, socket) do
    questions = socket
                |> get_room_pid()
                |> Room.get_questions()
    push socket, "question_list", %{"questions" => questions}
    {:noreply, socket}
  end
  def handle_in("finish_game", %{"game" => q_and_a}, socket) do
    res = socket
    |> get_room_pid()
    |> Room.submit_answers(q_and_a, socket.assigns.user_id)
    case res do
      {:error, _} ->
        push socket, "error", %{"reason" => ""}
      {:ok, :game_not_finished} ->
        broadcast! socket, "player_finished", %{"user_id" => socket.assigns.user_id,
                                               "game_finished" => false}
      {:ok, :game_finished, final_q_and_a} ->
        broadcast! socket, "player_finished", %{"user_id" => socket.assigns.user_id,
                                               "game_finished" => true,
                                               "q_and_a" => final_q_and_a}
    end
    {:noreply, socket}
  end

  defp reason_to_msg(:user_ready), do: "You cannot add questions in ready state"
  defp reason_to_msg(:game_has_already_started), do: "Game has already started"

  defp get_room_name(%{topic: "room:" <> room_name}), do: room_name

  defp get_room_pid(socket) do
    res = socket
    |> get_room_name() 
    |> RoomsManager.get_room_by_name()
    case res do
      {:error, :not_exists} = e ->
        IO.puts "Tried to connect to room that does not exist"
        e
      {:ok ,pid} ->
        pid
    end
  end


  defp can_join?(user) do
    case User.in_room?(user) do
      false ->
        true
      true ->
        {false, "User has already joined another room"}
    end
  end

end
