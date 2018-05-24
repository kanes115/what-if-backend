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
        WhatIf.Endpoint.broadcast(topic, "user_joined", %{"user" => user.display_name})
        {:ok, socket}
    end
    {:ok, socket}
  end

  def handle_in("leave_room", %{}, %{topic: "room_name:" <> room_name} = socket) do
    room = RoomsManager.get_room_by_name(room_name)
    user_id = socket.assigns.user_id
    case Room.delete_user(room, user_id) do
      :ok ->
        broadcast! socket, "user_left", %{"user" => User.get_user_by_id(user_id)}
      {:error, reason} ->
        push socket, "error_leaving", %{"user" => User.get_user_by_id(user_id),
          "reason" => reason}
    end
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
    broadcast! socket, "ready", %{"user" => user.display_name}
    {:noreply, socket}
  end

  defp get_room_name(%{topic: "room:" <> room_name}), do: room_name

  defp can_join?(user) do
    case User.in_room?(user) do
      false ->
        true
      true ->
        {false, "User has already joined another room"}
    end
  end

end
