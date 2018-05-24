defmodule WhatIf.PageController do
  use WhatIf.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def test(conn, _params) do
    json conn, %{test: "ok"}
  end

  def set_display_name(conn, %{"name" => name}) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        register(token, name, conn)
        conn
        |> put_status(200)
        |> send_resp(200, "ok")
      _ ->
        conn
        |> put_status(403)
        |> send_resp(403, "Unauthorized")
        |> halt
    end
  end

  def register(token, name, conn) do
    user_id = WhatIf.User.get_user_id(token)
    changeset = 
      WhatIf.User.registration_changeset(%WhatIf.User{}, %{display_name: name, user_id: user_id})
    case Repo.insert(changeset) do
      {:ok, _user} ->
        conn
      {:error, _changeset} ->
        IO.inspect("Error at inserting to db")
    end

  end

end
