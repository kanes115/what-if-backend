defmodule WhatIf.PageControllerTest do
  use WhatIf.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end

  test "GET /test", %{conn: conn} do
    conn = get conn, "/test"
    assert json_response(conn, 200) == %{"test" => "ok"}
  end

  test "GET /games with no authorization header return 403", %{conn: conn} do
    conn = get conn, "/games"
    assert response(conn, 403) =~ "Unauthorized"
  end

  test "GET /game/:id with no authorization header return 403 even when :id does not exist",
  %{conn: conn} do
    conn = get conn, "/game/2334"
    assert response(conn, 403) =~ "Unauthorized"
  end

end
