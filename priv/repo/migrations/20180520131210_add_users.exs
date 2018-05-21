defmodule WhatIf.Repo.Migrations.AddUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :user_id, :string 
      add :display_name, :string

      timestamps()
    end
    create unique_index(:users, [:user_id])
  end
end
