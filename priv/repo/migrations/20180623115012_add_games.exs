defmodule WhatIf.Repo.Migrations.AddGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :game_id, :serial, primary_key: true
      add :room_name, :string
      add :questions, :string

      timestamps()
    end
    create unique_index(:games, [:game_id])

    create table(:users_games, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :string)
      add :game_id, references(:games, column: :game_id)
    end
  end
end
