defmodule WhatIf.LobbyTest do
  use WhatIf.ChannelCase
  import Phoenix.ConnTest, except: [connect: 2]

  @token "eyJhbGciOiJSUzI1NiIsImtpZCI6IjYyMDg0NmQxNDVjN2VjNjQ0ODU5MmFjZWYzMGVhYmE1NzA4NmMwYWUifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vdGFpLXdoYXQtaWYiLCJhdWQiOiJ0YWktd2hhdC1pZiIsImF1dGhfdGltZSI6MTUyOTkzOTUzOSwidXNlcl9pZCI6InZZc2s4dnk0MUtoUDVpdHFXZEYxRnd3RFRpYzIiLCJzdWIiOiJ2WXNrOHZ5NDFLaFA1aXRxV2RGMUZ3d0RUaWMyIiwiaWF0IjoxNTI5OTM5NTYyLCJleHAiOjE1Mjk5NDMxNjIsImVtYWlsIjoidGVzdF91c2VyQG5lY2Vzc2FyeWZvcnRlc3RzLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJ0ZXN0X3VzZXJAbmVjZXNzYXJ5Zm9ydGVzdHMuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifX0.RgJEgOvu7T7ivxUnp83i9xzVyouzo2dbUWZFXuhcL-Y8BqisZn_QkhFoVZrd-Ji1iNPihXSJ4_46jUMEp0bkLfwoz98mBFa8G87zLO_50dI5yuFe1JWkKU8GX-Jo_KU9duhsIcgWsynCGfpFdhHtT0KTEUVOjg-mDWHFTF4HTk7Ezn7IDTOB7rcsGEjr9DIBC9cJ8FDxxNebB5bHMMYEOBPhgRH1_VZqUk-gsWa0H-zzA9Pw_u6gsibFM_3UKet9eIVAIFvvI4TwSqIFc--JY1mVpHAWDHDoYpBQBekL3y9YMhDB7UwQWHn9_oYumQfobTH0Ktv29L8dlvWZ0ADfEw"

  test "Can't connect to lobby if token is not specified", _ do
    assert :error = connect(WhatIf.UserSocket, %{})
  end

  test "User can't join the lobby if they didn't specify nickname", _ do
    assert {:ok, socket} = connect(WhatIf.UserSocket, %{"token" => @token})
    assert {:error, resp} = subscribe_and_join(socket, "lobby:a")
    assert %{code: 401, reason: reason} = resp
    assert reason =~ "not registered"
  end

  test "User can join the lobby if they provided nickname beforehand", _ do
    conn = build_conn()
           |> put_req_header("authorization", "Bearer #{@token}")
           |> post("/display-name", [name: "Alicja"])
    assert conn.status == 201
    assert {:ok, socket} = connect(WhatIf.UserSocket, %{"token" => @token})
    assert {:ok, %{}, _socket} = subscribe_and_join(socket, "lobby:a")
  end

  defp put_req_header(conn, name, value) do
    %{conn | req_headers: [{name, value} | conn.req_headers]}
  end
end
