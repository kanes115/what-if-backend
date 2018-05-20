defmodule WhatIf.PageController do
  use WhatIf.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def test(conn, _params) do
    json conn, %{test: "ok"}
  end

  def set_display_name(conn, %{"user_id" => user_id, "name" => name}) do
    # insert (user_id, name) to db
    changeset = 
      WhatIf.User.registration_changeset(WhatIf.User, %{display_name: name, user_id: user_id})
    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
      {:error, changeset} ->
        IO.inspect("Error at inserting to db")
    end
  end

end
