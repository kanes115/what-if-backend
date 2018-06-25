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
        kid = get_kid(token)
        firebase_keys = get_public_keys()
        case Map.get(firebase_keys, kid) do
          jwk = %JOSE.JWK{} ->
            verified = JOSE.JWT.verify_strict(jwk, ["RS256"], token)
            case verified do
              {true, fields, _} ->
                assign(conn, :user_id, fields.fields["user_id"])
              _ ->
                conn |> unauthorized
            end
          e ->
            conn |> unauthorized
        end
      _ ->
        conn |> unauthorized
    end
  end

  defp get_kid(token) do
    try do
      token
      |> JOSE.JWS.peek_protected()
      |> JOSE.decode()
      |> Map.get("kid")
    catch
      e, f ->
        nil
    end

  end

  defp unauthorized(conn) do
    conn
        |> put_status(403)
        |> send_resp(403, "Unauthorized")
        |> halt
  end


  defp get_public_keys() do
        {:ok, {{_, 200, _}, _, body}} = :httpc.request(:get, {'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com', []}, [autoredirect: true], [])
    JOSE.JWK.from_firebase(IO.iodata_to_binary(body))
  end

  # Other scopes may use custom stacks.
  # scope "/api", WhatIf do
  #   pipe_through :api
  # end
end
