defmodule WhatIf.Game do
  use Ecto.Schema
  import Ecto.Query

  alias WhatIf.Repo

  @primary_key {:game_id, :id, autogenerate: true}
  schema "games" do
    field :room_name, :string
    field :questions, :string

    many_to_many :users, WhatIf.User,
      join_through: "users_games", join_keys: [game_id: :game_id, user_id: :user_id]

    timestamps()

  end

  def changeset(game, params \\ %{}) do
    game
    |> Ecto.Changeset.cast(params, [:room_name, :questions])
    |> Ecto.Changeset.validate_required([:room_name, :questions])
    |> Ecto.Changeset.put_assoc(:users, params[:users])
  end

  def get_all do
    __MODULE__ |> WhatIf.Repo.all
  end

  def get_user_games_list(query \\ __MODULE__, user_id) do
    q = from t in query,
      join: u in assoc(t, :users),
      where: u.user_id == ^user_id,
      select: {t.game_id, t.room_name, t.inserted_at}
    Repo.all(q)
  end

  def get_game_by_id(game_id) do
    Repo.get_by(__MODULE__, game_id: game_id)
    |> Repo.preload(:users)
  end

end
