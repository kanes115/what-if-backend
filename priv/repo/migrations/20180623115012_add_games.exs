defmodule WhatIf.Repo.Migrations.AddGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :game_id, :id, primary_key: true

      timestamps()
    end
    create table(:users_games, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :string)
      add :game_id, references(:games, column: :game_id)

      timestamps()
    end
  end
end
