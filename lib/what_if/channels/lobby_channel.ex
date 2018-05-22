defmodule WhatIf.LobbyChannel do
  use Phoenix.Channel

  def join("lobby:" <> _action, _message, socket) do
    case WhatIf.User.exists?(socket.assigns.user_id) do
      true ->
        {:ok, socket}
      false ->
        {:error, %{reason: "User not registered"}}
    end
  end

  def handle_in("create_room", %{"name" => name}, socket) do
    case WhatIf.RoomsManager.add_room(name) do
      {:error, reason} ->
        push socket, "error", %{"reason" => reason, "name" => name}
      {:ok, _pid} ->
        broadcast! socket, "room_created", %{"name" => name}
    end
    {:noreply, socket}
  end
  def handle_in("get_rooms", %{}, socket) do
    rooms = WhatIf.RoomsManager.get_all_rooms()
            |> Enum.map(fn {name, _pid} -> name end)
    push socket, "rooms_list", %{"rooms" => rooms}
    {:noreply, socket}
  end
  def handle_in("delete_room", %{"name" => name}, socket) do
    case WhatIf.RoomsManager.delete_room(name) do
      {:error, reason} ->
        push socket, "error_when_deleting", %{"reason" => reason, "name" => name}
      :ok ->
        broadcast! socket, "room_deleted", %{"name" => name}
    end
    {:noreply, socket}
  end
  def handle_in("join_room", %{"name" => room_name}, socket) do
    user_id = WhatIf.User.get_user_id(socket.assigns.user_id)
    user = WhatIf.User.get_user_by_id(user_id)
    case WhatIf.RoomsManager.get_room_by_name(room_name) do
      {:ok, pid} ->
        WhatIf.Room.add_user(pid, user)
        push socket, "joined", %{"name" => room_name}
      {:error, reason} ->
        push socket, "error_while_joining", %{"name" => room_name, "reason" => reason}
    end
    {:noreply, socket}
  end

end
