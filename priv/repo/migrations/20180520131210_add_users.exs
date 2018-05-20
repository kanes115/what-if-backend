defmodule WhatIf.Repo.Migrations.AddUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :user_id, :string

      timestamps()
    end
    create unique_index(:users, [:user_id])
  end
end
