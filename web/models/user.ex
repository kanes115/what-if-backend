defmodule WhatIf.User do
  use Ecto.Schema

  alias WhatIf.Repo

  @primary_key {:user_id, :string, autogenerate: false}
  schema "users" do
    field :display_name, :string
    many_to_many :games, WhatIf.Game,
      join_through: "users_games", join_keys: [user_id: :user_id, game_id: :game_id]

    timestamps()
  end

  def exists?(user_id) do
    case Repo.get(WhatIf.User, user_id, []) do
      nil ->
        false
      _ ->
        true
    end
  end

  def registration_changeset(user, params \\ %{}) do
    user
    |> Ecto.Changeset.cast(params, [:display_name, :user_id])
    |> Ecto.Changeset.validate_required([:display_name, :user_id])
  end

  def get_all do
    __MODULE__ |> WhatIf.Repo.all
  end

  def get_user_id(token), do: token # to implements

  def get_user_by_id(id) do
    Repo.get_by(__MODULE__, user_id: id)
  end

  def get_user(email) do
    Repo.get_by(__MODULE__, email: email)
  end

  def in_room?(user), do: false # todo

end
