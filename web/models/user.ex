defmodule WhatIf.User do
  use Ecto.Schema

  alias FileFlow.Repo

  @primary_key {:user_id, :string, autogenerate: false}
  schema "users" do
    field :display_name, :string
    has_many :games, WhatIf.Game

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

  def get_user(email) do
    Repo.get_by(WhatIf.User, email: email)
  end

end
