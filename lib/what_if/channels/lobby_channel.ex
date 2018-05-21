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

  def handle_in("crete_room", %{"name" => name}, socket) do
    spec = %{id: name, start: {WhatIf.Room, :start_link, [name]}}
    {:ok, _pid} = DynamicSupervisor.start_child(WhatIf.RoomsSupervisor, spec) # here case needed
    #broadcast! socket, "new_msg", %{body: body}
    {:noreply, socket}
  end

end
