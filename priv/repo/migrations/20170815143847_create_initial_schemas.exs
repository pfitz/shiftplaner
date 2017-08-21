defmodule Shiftplaner.Repo.Migrations.CreateInitialSchemas do
  use Ecto.Migration

  def change do

    create table(:event, primary_key: false)do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :active, :boolean

      timestamps()
    end

    create table(:weekend, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :event_id, references(:event, type: :uuid)

      timestamps()
    end

    create table(:day, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :date, :date
      add :weekend_id, references(:weekend, type: :uuid)

      timestamps()
    end

    create table(:person, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :first_name, :string
      add :sure_name, :string
      add :email, :string
      add :phone, :string
      add :is_griller, :boolean

      timestamps()
    end

    create table(:shift, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :worker_needed, :integer
      add :griller_needed, :integer
      add :start_time, :time
      add :end_time, :time
      add :day_id, references(:day, type: :uuid)

      timestamps()
    end

    create table(:persons_available_shifts, primary_key: false) do
      add :person_id, references(:person, type: :uuid)
      add :shift_id, references(:shift, type: :uuid)
    end

    create table(:persons_dispositioned_shifts, primary_key: false) do
      add :person_id, references(:person, type: :uuid)
      add :shift_id, references(:shift, type: :uuid)
    end

    create table(:persons_dispositioned_griller_shifts, primary_key: false) do
      add :person_id, references(:person, type: :uuid)
      add :shift_id, references(:shift, type: :uuid)
    end

    create unique_index(:persons_available_shifts, [:person_id, :shift_id])
    create unique_index(:persons_dispositioned_shifts, [:person_id, :shift_id])
    create unique_index(:persons_dispositioned_griller_shifts, [:person_id, :shift_id])
  end
end
