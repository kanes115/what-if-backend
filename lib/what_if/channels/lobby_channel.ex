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
        push socket, "error", %{"reason" => reason}
      :ok ->
        push socket, "ok", %{}
    end
    {:noreply, socket}
  end

end
