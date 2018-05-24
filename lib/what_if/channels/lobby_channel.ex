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
    rooms = WhatIf.RoomsManager.get_all_rooms_names()
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
  
end
