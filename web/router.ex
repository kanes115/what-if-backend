defmodule WhatIf.Router do
  use WhatIf.Web, :router

  import Joken

  pipeline :browser do
    #plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Joken.Plug, verify: &__MODULE__.verify_function/0
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WhatIf do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index, private: %{joken_skip: true}

    get "/test", PageController, :test, private: %{joken_skip: true}

    post "/display-name", PageController, :set_display_name, private: %{joken_skip: true}
  end

  def verify_function() do
    key = JOSE.JWK.from_pem_file("cert.pem")
    IO.puts "plug turned on"
    res = %Joken.Token{}
    |> Joken.with_signer(rs256(key))
    IO.inspect res
    res
  end

  # Other scopes may use custom stacks.
  # scope "/api", WhatIf do
  #   pipe_through :api
  # end
end
