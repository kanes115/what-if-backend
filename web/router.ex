defmodule WhatIf.Router do
  use WhatIf.Web, :router
  import Joken


  pipeline :browser do
    plug Joken.Plug, verify: &__MODULE__.verify_function/0
    #plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    #plug :protect_from_forgery
    plug :put_secure_browser_headers
    # plug :verify_jwt
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WhatIf do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    get "/test", PageController, :test

    get "/games", PageController, :get_games
    get "/game/:game_id", PageController, :get_game_details

    post "/display-name", PageController, :set_display_name
  end

  def verify_function() do
    key = get_public_key()
    IO.puts "plug turned on"
    res = %Joken.Token{}
    |> Joken.with_signer(rs256(key))
    IO.inspect res
    res
  end

  def verify_jwt(conn, opts) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        IO.inspect token
        opts = %{
          alg: "RS256",
          key: get_public_key()
        }
        try do
          {:ok, claims} = JsonWebToken.verify(token, opts)
          conn
        rescue
          error -> 
            raise error
            unauthorized(conn)
        end
      _ ->
        unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
        |> put_status(403)
        |> send_resp(403, "Unauthorized")
        |> halt
  end


  defp get_public_key() do
    url = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
    response = HTTPoison.get!(url)
    res = Poison.decode!(response.body)
    res
    #[cert | _] = for {k, v} <- res, do: k
    #IO.inspect cert
    #cert
  end

  # Other scopes may use custom stacks.
  # scope "/api", WhatIf do
  #   pipe_through :api
  # end
end
