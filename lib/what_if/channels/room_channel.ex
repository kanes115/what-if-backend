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

  def terminate({:shutdown, _}, socket) do
    room = socket
           |> get_room_pid() 
    user_id = socket.assigns.user_id
    joined_user = User.get_user_by_id(user_id)
    Room.delete_user(room, user_id)
    broadcast! socket, "user_left", %{"user_id" => joined_user.user_id}
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
    socket
    |> get_room_pid() 
    |> Room.add_question(question)
    broadcast! socket, "new_question", body
    {:noreply, socket}
  end
  def handle_in("get_questions", %{}, socket) do
    questions = socket
                |> get_room_pid()
                |> Room.get_questions()
    push socket, "question_list", %{"questions" => questions}
    {:noreply, socket}
  end


  defp get_room_name(%{topic: "room:" <> room_name}), do: room_name

  defp get_room_pid(socket) do
    {:ok, pid} = socket
    |> get_room_name() 
    |> RoomsManager.get_room_by_name()
    pid
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
