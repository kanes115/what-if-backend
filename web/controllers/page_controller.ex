defmodule WhatIf.PageController do
  use WhatIf.Web, :controller

  defmodule TermParser do
    def parse(str) when is_binary(str)do
      case str |> Code.string_to_quoted do
        {:ok, terms} -> hydrate_terms(terms)
        {:error, err} -> {:error, err}
      end
    end

    defp hydrate_terms(terms) do
      try do
        {:ok, _parse(terms)}
      rescue
        e in ArgumentError -> {:error, e}
      end
    end

    # atomic terms
    defp _parse(term) when is_atom(term), do: term
    defp _parse(term) when is_integer(term), do: term
    defp _parse(term) when is_float(term), do: term
    defp _parse(term) when is_binary(term), do: term

    defp _parse([]), do: []
    defp _parse([h|t]), do: [_parse(h) | _parse(t)]

    defp _parse({a, b}), do: {_parse(a), _parse(b)}
    defp _parse({:"{}", _place, terms}) do
      terms
      |> Enum.map(&_parse/1)
      |> List.to_tuple
    end

    defp _parse({:"%{}", _place, terms}) do
      for {k, v} <- terms, into: %{}, do: {_parse(k), _parse(v)}
    end

    defp _parse(_) do
      raise ArgumentError, message: "string contains non-literal term(s)"
    end

  end


  def index(conn, _params) do
    render conn, "index.html"
  end

  def test(conn, _params) do
    json conn, %{test: "ok"}
  end

  def set_display_name(conn, %{"name" => name}) do
    fun = fn user_id ->
      register(user_id, name, conn)
      {201, "ok"}
    end
    maybe_do(conn, fun)
  end

  def register(user_id, name, conn) do
    changeset = 
      WhatIf.User.registration_changeset(%WhatIf.User{}, %{display_name: name, user_id: user_id})
    case Repo.insert(changeset) do
      {:ok, _user} ->
        conn
      {:error, _changeset} ->
        IO.inspect("Error at inserting to db")
    end
  end

  def get_games(conn, _params) do
    fun = fn user_id ->
      games = WhatIf.Game.get_user_games_list(user_id)
              |> Enum.map(fn {id, name, date} ->
                %{"id" => id, "room_name" => name, "date" => date} end)
                {200, %{"games" => games}}
    end
    maybe_do(conn, fun)
  end

  def get_game_details(conn, %{"game_id" => game_id}) do
    fun = fn _user_id ->
      game = WhatIf.Game.get_game_by_id(game_id)
      case game do
        nil ->
          {404, "Game not found"}
        _ ->
          users = game.users
                  |> Enum.map(fn %{display_name: name} -> name end)
          {:ok, json_q} = TermParser.parse(game.questions)
          {200, %{"q_and_a" => json_q, "players" => users}}
      end
    end
    maybe_do(conn, fun)
  end

  defp maybe_do(conn, fun) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        user_id = WhatIf.User.get_user_id(token)
        {code, response} = fun.(user_id)
        case is_map(response) do
          true ->
            json conn, response
          false ->
            conn
            |> put_status(code)
            |> send_resp(code, response)
        end
      _ ->
        conn
        |> put_status(403)
        |> send_resp(403, "Unauthorized")
        |> halt
    end
  end

  
end
