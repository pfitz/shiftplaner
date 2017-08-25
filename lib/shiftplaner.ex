defmodule Shiftplaner do
  @moduledoc """
  Documentation for Shiftplaner.
  """

  ##################################################################
  ####
  ####          Event functions
  ####
  ##################################################################

  @doc """
  creates a changeset for the given ```event```

  event = An event of type ```%Shiftplaner.Event{}```

  Returns an ```%Ecto.Changeset{}``` for the ```%Shiftplaner.Event{}```
  """
  @spec change_event(Shiftplaner.Event.t) :: Ecto.Changeset.t
  defdelegate change_event(event), to: Shiftplaner.Event

  @doc """
  Tries to create an event from the given ```attrs```.

  Returns either ```{:ok, event}``` or ```{:error, changeset}```
  """
  @spec create_event(map) :: {:ok, Shiftplaner.Event.t} | {:error, Ecto.Changeset.t}
  defdelegate create_event(attrs), to: Shiftplaner.Event

  @doc """
  It returns {:ok, event} if the struct has been successfully deleted or {:error, changeset}
  if there was a validation or a known constraint error.
  """
  @spec delete_event(Shiftplaner.Event.t) :: {:ok, Shiftplaner.Event.t} | {:error, Ecto.Changeset.t}
  defdelegate delete_event(event), to: Shiftplaner.Event

  @doc """
  Tries to get the event for the given binary uuid.

  Returns either an Event or nil or nothing.
  """
  @spec get_event(String.t) :: Shiftplaner.Event.t | {:error, :could_not_fetch_event}
  defdelegate get_event(id), to: Shiftplaner.Event

  @doc """
  Similiar to ```get_event/1``` but raises if no records is found.
  """
  @spec get_event!(String.t) :: Shiftplaner.Event.t | no_return
  defdelegate get_event!(id), to: Shiftplaner.Event

  @doc """
  Lists all active and inactive events and preloads the weekends.

  Returns a list of ```Shiftplaner.Event```
  """
  @spec list_all_events :: list(Shiftplaner.Event.t)
  defdelegate list_all_events, to: Shiftplaner.Event

  @doc """
  Updates the given ```Event```.

  If successful returns ```{:ok, updated_event}```.
  If unsuccesful returns ```{:error, changeset}```.
  """
  @spec update_event(Shiftplaner.Event.t, map) :: {:ok, Shiftplaner.Event} | {
    :error,
    Ecto.Changeset.t
  }
  defdelegate update_event(event, attrs), to: Shiftplaner.Event

  ##################################################################
  ####
  ####          Weekend functions
  ####
  ##################################################################

  @doc """
  Creates an ecto changeset for the given weekend.

  weekend = ```Shiftplaner.Weekend```

  returns ```%Ecto.Changeset{}``` for ```Shiftplaner.Weekend```
  """
  @spec change_weekend(Shiftplaner.Weekend.t) :: Ecto.Changeset.t
  defdelegate change_weekend(weekend), to: Shiftplaner.Weekend

  @doc """
  Tries to create a weekend from the given ```attrs```.

  Returns either ```{:ok, weekend}``` or ```{:error, changeset}```
  """
  @spec create_weekend(map) :: {:ok, Shiftplaner.Weekend.t} | {:error, Ecto.Changeset.t}
  defdelegate create_weekend(attrs), to: Shiftplaner.Weekend

  @doc """
  Tries to add a weekend from the given ```attrs``` to an existing ```event```.

  Returns either ```{:ok, event}``` or ```{:error, :could_not_add_weekend_to_event}```
  """
  @spec create_weekend_for_event(map, String.t) :: {:ok, Shiftplaner.Weekend.t} | {
    :error,
    :could_not_add_weekend_to_event
  }
  defdelegate create_weekend_for_event(attrs, event_id), to: Shiftplaner.Weekend

  @doc """
  It returns {:ok, weekend} if the struct has been successfully deleted or {:error, changeset}
  if there was a validation or a known constraint error.
  """
  @spec delete_weekend(Shiftplaner.Weekend.t) :: {:ok, Shiftplaner.Weekend.t} | {
    :error,
    Ecto.Changeset.t
  }
  defdelegate delete_weekend(weekend), to: Shiftplaner.Weekend

  @doc """
  Tries to get the weekend for the given binary uuid.

  Returns either a weekend or raises ```Ecto.NoResultsError``` if no record was found..
  """
  @spec get_weekend!(String.t) :: Shiftplaner.Weekend.t | no_return
  defdelegate get_weekend!(id), to: Shiftplaner.Weekend

  @doc """
  List all weekends for the given event.

  Returns a list of weekends.
  """
  @spec list_weekends_for_event(String.t) :: list(Shiftplaner.Weekend.t)
  defdelegate list_weekends_for_event(event_id), to: Shiftplaner.Weekend

  @doc """
  Updates the given ```Weekend```.

  If successful returns ```{:ok, updated_weekend}```.
  If unsuccesful returns ```{:error, changeset}```.
  """
  @spec update_weekend(Shiftplaner.Weekend.t, map) :: {:ok, Shiftplaner.Weekend} | {
    :error,
    Ecto.Changeset.t
  }
  defdelegate update_weekend(weekend, attrs), to: Shiftplaner.Weekend

  ##################################################################
  ####
  ####          Day functions
  ####
  ##################################################################

  @spec change_day(Shiftplaner.Day.t) :: Ecto.Changeset.t
  defdelegate change_day(day), to: Shiftplaner.Day

  @spec create_day(map) :: {:ok, Shiftplaner.Day.t} | {:error, Ecto.Changeset.t}
  defdelegate create_day(attrs), to: Shiftplaner.Day

  @spec delete_day(Shiftplaner.Day.t) :: {:ok, Shiftplaner.Day.t} | {:error, Ecto.Changeset.t}
  defdelegate delete_day(day), to: Shiftplaner.Day

  @spec get_day(String.t) :: {:ok, Shiftplaner.Day.t} | {:error, Ecto.Changeset.t}
  defdelegate get_day(id), to: Shiftplaner.Day

  @spec get_day!(String.t) :: Shiftplaner.Day.t | no_return
  defdelegate get_day!(id), to: Shiftplaner.Day

  @spec list_days :: list(Shiftplaner.Day.t)
  defdelegate list_days(), to: Shiftplaner.Day

  @spec list_days_for_weekend(String.t) :: list(Shiftplaner.Day.t)
  defdelegate list_days_for_weekend(weekend_id), to: Shiftplaner.Day

  @spec update_day(Shiftplaner.Day.t, map) :: {:ok, Shiftplaner.Day} | {
    :error,
    Ecto.Changeset.t
  }
  defdelegate update_day(day, attrs), to: Shiftplaner.Day

  ##################################################################
  ####
  ####          Shift functions
  ####
  ##################################################################

  @spec change_shift(Shiftplaner.Shift.t) :: Ecto.Changeset.t
  defdelegate change_shift(shift), to: Shiftplaner.Shift

  @spec create_shift(map) :: {:ok, Shiftplaner.Shift.t} | {:error, Ecto.Changeset.t}
  defdelegate create_shift(attrs), to: Shiftplaner.Shift

  @spec delete_shift(Shiftplaner.Shift.t) :: {:ok, Shiftplaner.Shift.t} | {:error, Ecto.Changeset.t}
  defdelegate delete_shift(shift), to: Shiftplaner.Shift

  @spec get_shift(String.t) :: {:ok, Shiftplaner.Shift.t} | {:error, :could_not_fetch_shift}
  defdelegate get_shift(id), to: Shiftplaner.Shift

  @spec get_shift!(String.t) :: Shiftplaner.Shift.t | no_return
  defdelegate get_shift!(id), to: Shiftplaner.Shift

  @spec list_shifts :: list(Shiftplaner.Shift.t)
  defdelegate list_shifts, to: Shiftplaner.Shift

  @spec list_shifts_for_day(String.t) :: list(Shiftplaner.Shift.t)
  defdelegate list_shifts_for_day(day_id), to: Shiftplaner.Shift

  @spec update_shift(Shiftplaner.Shift.t, map) :: {:ok, Shiftplaner.Shift.t} | {
    :error,
    Ecto.Changeset.t
  }
  defdelegate update_shift(shift, attrs), to: Shiftplaner.Shift

  ##################################################################
  ####
  ####          Person functions
  ####
  ##################################################################

  @doc """
  List all persons

  Returns a list of ```Shiftplaner.Person```
  """
  @spec list_persons :: list(Shiftplaner.Person.t)
  defdelegate list_persons, to: Shiftplaner.Person
end
