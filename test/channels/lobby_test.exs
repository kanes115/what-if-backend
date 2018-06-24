defmodule WhatIf.LobbyTest do
  use WhatIf.ChannelCase
  import Phoenix.ConnTest, except: [connect: 2]

  test "Can't connect to lobby if token is not specified", _ do
    assert :error = connect(WhatIf.UserSocket, %{})
    #assert {:error, resp} = subscribe_and_join(socket, "lobby:a")
    #assert %{status: _} = resp
  end

  test "User can't join the lobby if they didn't specify nickname", _ do
    assert {:ok, socket} = connect(WhatIf.UserSocket, %{"token" => "some token"})
    assert {:error, resp} = subscribe_and_join(socket, "lobby:a")
    assert %{code: 401, reason: reason} = resp
    assert reason =~ "not registered"
  end

  test "User can join the lobby if they provided nickname beforehand", _ do
    conn = build_conn()
           |> put_req_header("authorization", "Bearer some_token_here")
           |> post("/display-name", [name: "Alicja"])
    assert conn.status == 201
    assert {:ok, socket} = connect(WhatIf.UserSocket, %{"token" => "some_token_here"})
    assert {:ok, %{}, _socket} = subscribe_and_join(socket, "lobby:a")
  end

  defp put_req_header(conn, name, value) do
    %{conn | req_headers: [{name, value} | conn.req_headers]}
  end
end
