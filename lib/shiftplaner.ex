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
  @spec get_event(String.t) :: Shiftplaner.Event.t | nil | no_return
  defdelegate get_event(id), to: Shiftplaner.Event

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
