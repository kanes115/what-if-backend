defmodule WhatIf.RoomsManager do

  def get_all_rooms() do
    DynamicSupervisor.which_children(WhatIf.RoomsSupervisor)
    |> Enum.map(fn({:undefined, pid, _, _}) -> pid end)
    |> Enum.map(fn(pid) -> WhatIf.Room.get_name(pid) end)
  end

  def add_room(name) do
    spec = %{id: name, start: {WhatIf.Room, :start_link, [name]}}
    DynamicSupervisor.start_child(WhatIf.RoomsSupervisor, spec) #case, return error if exists
  end
  
end
