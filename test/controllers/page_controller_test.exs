defmodule WhatIf.PageControllerTest do
  use WhatIf.ConnCase

  @token "eyJhbGciOiJSUzI1NiIsImtpZCI6IjYyMDg0NmQxNDVjN2VjNjQ0ODU5MmFjZWYzMGVhYmE1NzA4NmMwYWUifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vdGFpLXdoYXQtaWYiLCJhdWQiOiJ0YWktd2hhdC1pZiIsImF1dGhfdGltZSI6MTUyOTkzOTUzOSwidXNlcl9pZCI6InZZc2s4dnk0MUtoUDVpdHFXZEYxRnd3RFRpYzIiLCJzdWIiOiJ2WXNrOHZ5NDFLaFA1aXRxV2RGMUZ3d0RUaWMyIiwiaWF0IjoxNTI5OTM5NTYyLCJleHAiOjE1Mjk5NDMxNjIsImVtYWlsIjoidGVzdF91c2VyQG5lY2Vzc2FyeWZvcnRlc3RzLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJ0ZXN0X3VzZXJAbmVjZXNzYXJ5Zm9ydGVzdHMuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifX0.RgJEgOvu7T7ivxUnp83i9xzVyouzo2dbUWZFXuhcL-Y8BqisZn_QkhFoVZrd-Ji1iNPihXSJ4_46jUMEp0bkLfwoz98mBFa8G87zLO_50dI5yuFe1JWkKU8GX-Jo_KU9duhsIcgWsynCGfpFdhHtT0KTEUVOjg-mDWHFTF4HTk7Ezn7IDTOB7rcsGEjr9DIBC9cJ8FDxxNebB5bHMMYEOBPhgRH1_VZqUk-gsWa0H-zzA9Pw_u6gsibFM_3UKet9eIVAIFvvI4TwSqIFc--JY1mVpHAWDHDoYpBQBekL3y9YMhDB7UwQWHn9_oYumQfobTH0Ktv29L8dlvWZ0ADfEw"

  test "GET / returns 403 if token is not provided", %{conn: conn} do
    conn = get conn, "/"
    assert response(conn, 403) =~ "Unauthorized"
  end


  test "GET / returns 200 with auth header", %{conn: _conn} do
    conn = build_conn()
    |> put_token_header
    |> get("/")
    assert html_response(conn, 200) =~ "Welcome"
  end

  test "GET /test", %{conn: _conn} do
    conn = build_conn()
           |> put_token_header
           |> get("/test")
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

  defp put_token_header(conn) do
    conn
    |> put_req_header("authorization", "Bearer #{@token}")
  end

end
