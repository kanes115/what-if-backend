defmodule WhatIf.RoomChannel do
  use Phoenix.Channel

  alias WhatIf.User
  alias WhatIf.Room
  alias WhatIf.RoomsManager

  def join("room:" <> room_name, _message, socket) do
    user_id = socket.assigns.user_id
    user = User.get_user_by_id(user_id)
    case {can_join?(user), RoomsManager.get_room_by_name(room_name)} do
      {{false, reason}, _} ->
        {:error, %{reason: reason}}
      {_, {:error, reason}} ->
        {:error, %{reason: reason}}
      {:ok, pid} ->
        Room.add_user(pid, user)
        {:ok, socket}
    end
    {:ok, socket}
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
