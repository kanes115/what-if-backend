defmodule WhatIf.Game do
  use Ecto.Schema

  schema "games" do
    field :room_name, :string

    belongs_to :user, WhatIf.User, foreign_key: :token

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
