defmodule WhatIf.Router do
  use WhatIf.Web, :router

  import Joken

  pipeline :browser do
    plug :verify_jwt
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WhatIf do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index, private: %{joken_skip: true}

    get "/test", PageController, :test

    get "/games", PageController, :get_games
    get "/game/:game_id", PageController, :get_game_details

    post "/display-name", PageController, :set_display_name
  end

  def verify_jwt(conn, opts) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case WhatIf.FirebaseVeryfier.verify_jwt(token) do
          {true, user_id} ->
            assign(conn, :user_id, user_id)
          _ ->
            conn |> unauthorized
        end
      _ ->
        conn |> unauthorized
    end
  end

  defp unauthorized(conn) do
    conn
        |> put_status(403)
        |> send_resp(403, "Unauthorized")
        |> halt
  end


    # Other scopes may use custom stacks.
  # scope "/api", WhatIf do
  #   pipe_through :api
  # end
end
