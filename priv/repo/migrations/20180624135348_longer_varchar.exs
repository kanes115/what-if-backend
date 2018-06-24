defmodule WhatIf.Repo.Migrations.LongerVarchar do
  use Ecto.Migration

  def change do
    alter table(:games) do
      modify :questions, :text
    end
  end
end
