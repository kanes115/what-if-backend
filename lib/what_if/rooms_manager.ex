defmodule WhatIf.RoomsManager do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, []}
  end

  def handle_call(:get_all_rooms, _from, rooms) do
    {:reply, rooms, rooms}
  end
  def handle_call({:add_room, name}, _from, rooms) do
    spec = %{id: name, start: {WhatIf.Room, :start_link, [name]}}
    {:ok, pid} = DynamicSupervisor.start_child(WhatIf.RoomsSupervisor, spec)
    {:reply, {:ok, pid}, [{name, pid} | rooms]}
  end
  def handle_call({:get_room_by_name, name}, _from, rooms) do
    result = rooms
         |> Enum.filter(fn {room_name, _pid} -> room_name == name end)
         |> Enum.map(fn {_room_name, pid} -> pid end)
    case result do
      [result_pid] ->
        {:reply, {:ok, result_pid}, rooms}
      _ ->
        {:reply, {:error, :not_exists}, rooms}
    end
  end
  def handle_call({:delete_room, name}, _from, rooms) do
    deleted_room_pid = rooms |> List.keyfind(name, 0)
    WhatIf.Room.delete_room(deleted_room_pid)
    new_rooms = rooms
                |> Enum.filter(fn {room_name, pid} -> name != room_name end)
    {:reply, :ok, new_rooms}
  end

  def get_all_rooms() do
    GenServer.call(__MODULE__, :get_all_rooms)
  end

  @spec add_room(String.t) :: {:error, :exists} | :ok
  def add_room(name) do
    case room_exists?(name) do
      true ->
        {:error, :exists}
      false ->
        GenServer.call(__MODULE__, {:add_room, name})
    end
  end

  def delete_room(name) do
    case room_exists?(name) do
      false ->
        {:error, :not_exists}
      true ->
        GenServer.call(__MODULE__, {:delete_room, name})
        :ok
    end
  end

  def room_exists?(name) do
    get_all_rooms()
    |> Enum.any?(fn {room_name, _pid} -> name == room_name end)
  end

  def get_room_by_name(name) do
    GenServer.call(__MODULE__, {:get_room_by_name, name})
  end

end
