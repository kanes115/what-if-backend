defmodule WhatIf.Game do
  use Ecto.Schema

  @primary_key {:game_id, :id, autogenerate: true}
  schema "games" do
    field :room_name, :string

    many_to_many :user, WhatIf.User,
      join_through: "users_games", join_keys: [game_id: :game_id, user_id: :user_id]

    timestamps()
  end

  def changeset(file, params \\ %{}) do
    file
    |> Ecto.Changeset.cast(params, [:path, :user_id])
    |> Ecto.Changeset.validate_required([:path, :user_id])
  end

  def get_all do
    __MODULE__ |> WhatIf.Repo.all
  end


end
