defmodule Shiftplaner.Weekend do
  @moduledoc false
  alias Shiftplaner.{Day, Repo, Weekend}
  import Ecto.{Query, Changeset}, warn: false
  require Logger
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type Ecto.UUID

  @type t :: %__MODULE__{event: Shiftplaner.Event.t, days: list(Shiftplaner.Day.t)}
  schema "weekend" do
    field :name
    belongs_to :event, Shiftplaner.Event
    has_many :days, Shiftplaner.Day, on_delete: :delete_all

    timestamps()
  end

  ##################################################################
  ####
  ####          Public API
  ####
  ##################################################################

  @doc """
  Creates an ecto changeset for the given weekend.

  weekend = ```Shiftplaner.Weekend```

  returns ```%Ecto.Changeset{}``` for ```Shiftplaner.Weekend```
  """
  @spec change_weekend(Shiftplaner.Weekend.t) :: Ecto.Changeset.t
  def change_weekend(%Weekend{} = weekend) do
    weekend_changeset(weekend, %{})
  end

  def changeset(%Weekend{} = weekend, params) do
    weekend_changeset(weekend, params)
  end

  @doc """
  Tries to create a weekend from the given ```attrs```.

  Returns either ```{:ok, weekend}``` or ```{:error, changeset}```
  """
  @spec create_weekend(map) :: {:ok, Shiftplaner.Weekend.t} | {:error, Ecto.Changeset.t}
  def create_weekend(attrs) do
    %Weekend{}
    |> weekend_changeset(attrs)
    |> Repo.insert()
    |> insert_result()
  end

  @doc """
  Tries to add a weekend from the given ```attrs``` to an existing ```event```.

  Returns either ```{:ok, event}``` or ```{:error, :could_not_add_weekend_to_event}```
  """
  @spec create_weekend_for_event(map, String.t) :: {:ok, Shiftplaner.Weekend.t} | {
    :error,
    :could_not_add_weekend_to_event
  }
  def create_weekend_for_event(attrs, event_id) when is_binary(event_id) do
    attrs = Map.put(attrs, "event_id", event_id)
    create_weekend(attrs)
  end

  @spec create_weekend_with_days(
          list(
            Shiftplaner.Day.t
          )
        ) :: {:ok, Shiftplaner.Weekend.t} | {:error, Ecto.Changeset.t}
  def create_weekend_with_days([%Day{} = d1, %Day{} = d2, %Day{} = d3]) do
    %Weekend{}
    |> weekend_changeset(%{})
    |> put_assoc(:days, [d1, d2, d3])
    |> Repo.insert
    |> insert_result()
  end

  @doc """
  It returns {:ok, weekend} if the struct has been successfully deleted or {:error, changeset}
  if there was a validation or a known constraint error.
  """
  @spec delete_weekend(Shiftplaner.Weekend.t) :: {:ok, Shiftplaner.Weekend.t} | {
    :error,
    Ecto.Changeset.t
  }
  def delete_weekend(%Weekend{} = weekend) do
    weekend
    |> Repo.delete()
  end

  @spec first_and_last_day_of_weekend(Shiftplaner.Weekend.t) :: {Date.t, Date.t}
  def first_and_last_day_of_weekend(%Weekend{} = weekend) do
    case days = list_all_days_for_weekend(weekend) do
      [] -> {:no_days, :no_days}
      _ ->
        {
          days
          |> List.first()
          |> Map.get(:date),
          days
          |> List.last()
          |> Map.get(:date)
        }
    end
  end

  @doc """
  List all weekends for the given event.

  Returns a list of weekends.
  """
  @spec list_weekends_for_event(String.t) :: list(Shiftplaner.Weekend.t)
  def list_weekends_for_event(event_id) when is_binary(event_id) do
    Weekend
    |> where([w], w.event_id == ^event_id)
    |> Repo.all
    |> Repo.preload(:days)
  end

  @spec list_all_days_for_weekend(Shiftplaner.Weekend.t) :: list(Shiftplaner.Day.t)
  def list_all_days_for_weekend(%Weekend{} = weekend), do: list_all_days_for_weekend(weekend.id)
  def list_all_days_for_weekend(weekend_id) do
    Day
    |> where([d], d.weekend_id == ^weekend_id)
    |> order_by([d], d.date)
    |> Repo.all
  end

  @doc """
  Tries to get the weekend for the given binary uuid.

  Returns either a weekend or raises ```Ecto.NoResultsError``` if no record was found..
  """
  @spec get_weekend!(String.t) :: Shiftplaner.Weekend.t | no_return
  def get_weekend!(id) when is_binary(id) do
    Weekend
    |> where([w], w.id == ^id)
    |> Repo.one
    |> Repo.preload(:days)
  end

  @doc """
    Updates the given ```Weekend```.

  If successful returns ```{:ok, updated_weekend}```.
  If unsuccesful returns ```{:error, changeset}```.
  """
  @spec update_weekend(Shiftplaner.Weekend.t, map) :: {:ok, Shiftplaner.Weekend} | {
    :error,
    Ecto.Changeset.t
  }
  def update_weekend(%Weekend{} = weekend, attrs) do
    weekend
    |> weekend_changeset(attrs)
    |> Repo.update()
  end

  ##################################################################
  ####
  ####          Private functions
  ####
  ##################################################################

  defp insert_result({:ok, %Weekend{} = weekend}) do
    fn -> Logger.debug "successfully inserted weekend"  end
    {:ok, weekend}
  end

  defp insert_result({:error, reason}) do
    fn -> Logger.warn "could not insert weekend!" end
    {:error, reason}
  end

  defp weekend_changeset(%Weekend{} = weekend, attrs) do
    weekend
    |> Repo.preload(:days)
    |> cast(attrs, [:name, :event_id])
    |> cast_assoc(:days, with: :change_day)
  end
end
