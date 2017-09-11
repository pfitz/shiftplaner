defmodule Shiftplaner.Event do
  @moduledoc false

  use Ecto.Schema

  alias Shiftplaner.{Event, Repo, Weekend}

  import Ecto.{Query, Changeset}, warn: false

  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type Ecto.UUID
  @preloads :weekends

  @type id :: String.t
  @type t :: %__MODULE__{name: String.t, active: boolean, weekends: list(Shiftplaner.Weekend.t)}
  schema "event" do
    field :name
    field :active, :boolean, default: false

    has_many :weekends, Weekend, on_delete: :delete_all

    timestamps()
  end

  @spec add_weekend_to_event(Shiftplaner.Event.t, Shiftplaner.Weekend.t)
        :: {:ok, Shiftplaner.Event.t} | {:error, Ecto.Changeset.t}
  def add_weekend_to_event(%Event{} = event, list_of_events) when is_list(list_of_events) do
    Enum.each(list_of_events, &add_weekend_to_event(event, &1))
  end

  def add_weekend_to_event(%Event{} = event, %Weekend{} = weekend) do
    event
    |> event_changeset(%{})
    |> put_assoc(:weekends, [weekend])
    |> Repo.update()
    |> update_result()
  end

  def add_weekend_to_event(%Event{} = event, attrs) when is_map(attrs) do
    event
    |> event_changeset(attrs)
    |> Repo.update()
    |> update_result()

  end

  @doc """
  Tries to create an event from the given ```attrs```.

  Returns either ```{:ok, event}``` or ```{:error, changeset}```
  """
  @spec create_event(map) :: {:ok, Shiftplaner.Event.t} | {:error, Ecto.Changeset.t}
  def create_event(attrs) do
    %Event{}
    |> event_changeset(attrs)
    |> Repo.insert()
    |> insert_result()
  end

  @doc """
  creates a changeset for the given ```event```

  event = An event of type ```%Shiftplaner.Event{}```

  Returns an ```%Ecto.Changeset{}``` for the ```%Shiftplaner.Event{}```
  """
  @spec change_event(Shiftplaner.Event.t) :: Ecto.Changeset.t
  def change_event(%Event{} = event) do
    event_changeset(event, %{})
  end

  @doc """
  It returns {:ok, event} if the struct has been successfully deleted or {:error, changeset}
  if there was a validation or a known constraint error.
  """
  @spec delete_event(Shiftplaner.Event.t) :: {:ok, Shiftplaner.Event.t} | {:error, Ecto.Changeset.t}
  def delete_event(%Event{} = event) do
    event
    |> Repo.delete()
  end

  @doc """
  Lists all active and inactive events and preloads the weekends.

  Returns a list of ```Shiftplaner.Event```
  """
  @spec list_all_events :: list(Shiftplaner.Event.t)
  def list_all_events do
    Event
    |> Repo.all()
    |> Repo.preload(:weekends)
  end

  @doc """
  Lists all active Events. Struct is fully preloded.
  """
  @spec list_all_active_events :: list(Shiftplaner.Event.t)
  def list_all_active_events do
    Event
    |> where([e], e.active == true)
    |> join(:left, [e], weekends in assoc(e, :weekends))
    |> join(:left, [e, w], days in assoc(w, :days))
    |> join(:left, [e, w, d], shifts in assoc(d, :shifts))
    |> join(:left, [e, w, d, s], available_persons in assoc(s, :available_persons))
    |> join(:left, [e, w, d, s], dispositioned_persons in assoc(s, :dispositioned_persons))
    |> join(:left, [e, w, d, s], dispositioned_griller in assoc(s, :dispositioned_griller))
    |> preload(
         [
           _,
           weekends,
           days,
           shifts,
           available_persons,
           dispositioned_persons,
           dispositioned_griller
         ],
         [
           weekends: {
             weekends,
             days: {
               days,
               shifts: {
                 shifts,
                 available_persons: available_persons,
                 dispositioned_persons: dispositioned_persons,
                 dispositioned_griller: dispositioned_griller
               }
             }
           }
         ]
       )
    |> order_by(
         [e, w, d, s, ava_p, disp_p, disp_g],
         [e.inserted_at, d.date, s.start_time, disp_p.sure_name]
       )
    |> Repo.all

  end

  @doc """
  List all shift ids for an given event.

  event: either an event_id or an ```Shiftplaner.Event```

  Returns: a list of all shift ids for an given event.
  """
  @spec list_all_shifts_for_event(
          Shiftplaner.Event.t | Shiftplaner.Event.id
        )
        :: list(Shiftplaner.Shift.id) | no_return
  def list_all_shifts_for_event(%Event{} = event) do
    list_all_shifts_for_event(event.id)
  end

  def list_all_shifts_for_event(event_id) when is_binary(event_id) do
    query = from e in Event,
                 where: e.id == ^event_id,
                 join: w in assoc(e, :weekends),
                 join: d in assoc(w, :days),
                 join: s in assoc(d, :shifts),
                 select: s.id
    Repo.all(query)
  end

  @doc """
  Tries to get the event for the given binary uuid.

  Returns either an Event or nil or nothing.
  """
  @spec get_event(String.t) :: {:ok, Shiftplaner.Event.t} | {:error, :could_not_fetch_event}
  def get_event(id) when is_binary(id) do
    Event
    |> where([e], e.id == ^id)
    |> Repo.one
    |> Repo.preload(:weekends)
    |> result_to_tuple()
  end

  @doc """
  Similiar to ```get_event/1``` but raises if no records is found.
  """
  @spec get_event!(String.t) :: Shiftplaner.Event.t | no_return
  def get_event!(id) when is_binary(id) do
    case get_event(id) do
      {:ok, event} -> event
      {:error, _} -> raise RuntimeError, message: "Could not fetch event :("
    end
  end

  def preload_all(%Event{} = event) do
    query = from e in Event,
                 where: e.id == ^event.id,
                 left_join: weekends in assoc(e, :weekends),
                 left_join: days in assoc(weekends, :days),
                 left_join: shifts in assoc(days, :shifts),
                 preload: [weekends: {weekends, days: {days, :shifts}}]
    Repo.one(query)
  end

  @doc """
  Updates the given ```Event```.

  If successful returns ```{:ok, updated_event}```.
  If unsuccesful returns ```{:error, changeset}```.
  """
  @spec update_event(Shiftplaner.Event.t, map) :: {:ok, Shiftplaner.Event} | {
    :error,
    Ecto.Changeset.t
  }
  def update_event(%Event{} = event, attrs) do
    event
    |> event_changeset(attrs)
    |> Repo.update()
    |> update_result()
  end

  defp event_changeset(%Event{} = event, attrs) do
    event
    |> Repo.preload(@preloads)
    |> cast(attrs, [:name, :active])
    |> cast_assoc(:weekends)
    |> validate_required([:name])
  end

  defp insert_result({:ok, %Event{} = event}) do
    Logger.debug fn ->
      "successfully inserted event - #{event.id}: #{event.name}"
    end
    {:ok, event}
  end

  defp insert_result({:error, reason}) do
    Logger.warn fn -> "Could not insert event - #{reason}" end
    {:error, reason}
  end

  defp result_to_tuple(%Event{} = event) do
    {:ok, event}
  end

  defp result_to_tuple(_) do
    {:error, :could_not_fetch_event}
  end

  defp update_result({:ok, %Event{} = event}) do
    Logger.debug fn ->
      "successfully updated event - #{event.id}: #{event.name}"
    end
    {:ok, event}
  end

  defp update_result({:error, reason}) do
    Logger.warn fn -> "Could not update event - #{reason}" end
    {:error, reason}
  end
end
