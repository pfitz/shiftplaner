defmodule Shiftplaner.Day do
  @moduledoc false

  use Ecto.Schema

  alias Shiftplaner.{Day, Repo, Shift, Weekend}

  import Ecto.{Query, Changeset}, warn: false

  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type Ecto.UUID

  @type t :: %__MODULE__{
               date: Date.t,
               weekend: Shiftplaner.Weekend.t,
               shifts: list(Shiftplaner.Shift.t)
             }
  schema "day" do
    field :date, :date

    belongs_to :weekend, Weekend
    has_many :shifts, Shift, on_delete: :delete_all

    timestamps()
  end

  ##################################################################
  ####
  ####          Public API
  ####
  ##################################################################

  @spec add_shift(
          Shiftplaner.Day.t,
          Shiftplaner.Shift.t | list(Shiftplaner.Shift.t)
        ) :: {
               :ok,
               Shiftplaner.Day.t
             } | {
               :error,
               Ecto.Changeset.t
             }
  def add_shift(%Day{} = day, %Shift{} = shift) do
    day
    |> day_changeset(%{})
    |> put_assoc(:shifts, [shift])
    |> Repo.update()
    |> update_result()
  end

  def add_shift(%Day{} = day, list_of_shifts) when is_list(list_of_shifts) do
    Enum.each(list_of_shifts, &add_shift(day, &1))
  end

  @spec change_day(Shiftplaner.Day.t) :: Ecto.Changeset.t
  def change_day(%Day{} = day) do
    day_changeset(day, %{})
  end

  @spec create_day(map) :: {:ok, Shiftplaner.Day.t} | {:error, Ecto.Changeset.t}
  def create_day(attrs) do
    %Day{}
    |> day_changeset(attrs)
    |> Repo.insert()
    |> insert_result()
  end

  @spec delete_day(Shiftplaner.Day.t) :: {:ok, Shiftplaner.Day.t} | {:error, Ecto.Changeset.t}
  def delete_day(%Day{} = day) do
    day
    |> Repo.delete()
  end

  @spec get_day(String.t) :: {:ok, Shiftplaner.Day.t} | {:error, Ecto.Changeset.t}
  def get_day(id) when is_binary(id) do
    Day
    |> where([d], d.id == ^id)
    |> Repo.one()
    |> Repo.preload(:shifts)
    |> result_to_tuple()
  end

  @spec get_day!(String.t) :: Shiftplaner.Day.t | no_return
  def get_day!(id) when is_binary(id) do
    case get_day(id) do
      {:ok, %Day{} = day} -> day
      _ -> raise RuntimeError, message: "could not fetch day for id: #{id}"
    end
  end

  @spec list_days :: list(Shiftplaner.Day.t)
  def list_days do
    Day
    |> Repo.all
  end

  @spec list_days_for_weekend(String.t) :: list(Shiftplaner.Day.t)
  def list_days_for_weekend(weekend_id) when is_binary(weekend_id) do
    Day
    |> where([d], d.weekend_id == ^weekend_id)
    |> order_by([d], d.date)
    |> Repo.all()
    |> Repo.preload(:shifts)
  end

  @spec update_day(Shiftplaner.Day.t, map) :: {:ok, Shiftplaner.Day} | {
    :error,
    Ecto.Changeset.t
  }
  def update_day(%Day{} = day, attrs) do
    day
    |> day_changeset(attrs)
    |> Repo.update()
  end

  ##################################################################
  ####
  ####          Private functions
  ####
  ##################################################################

  defp day_changeset(%Day{} = day, attrs) do
    day
    |> Repo.preload(:weekend)
    |> cast(attrs, [:date, :weekend_id])
    |> validate_required([:date, :weekend_id])
  end

  defp insert_result({:ok, %Day{} = day}) do
    Logger.debug fn -> "successfully inserted day - #{day.date}" end
    {:ok, day}
  end

  defp insert_result({:error, reason}) do
    Logger.warn fn -> "Could not insert Day - #{reason}" end
    {:error, reason}
  end

  defp update_result({:ok, %Day{} = day}) do
    Logger.debug fn ->
      "successfully updated day - #{day.id}: #{day.date}"
    end
    {:ok, day}
  end

  defp update_result({:error, reason}) do
    Logger.warn fn -> "Could not update day - #{reason}" end
    {:error, reason}
  end

  defp result_to_tuple(%Day{} = day) do
    {:ok, day}
  end

  defp result_to_tuple(_) do
    {:error, :could_not_fetch_day}
  end

end
