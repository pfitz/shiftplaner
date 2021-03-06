defmodule Shiftplaner.Person do
  @moduledoc """
  The `Shiftplaner.Person` modul handles all aspect of workers and grillers for the shiftplan.
  """

  alias Shiftplaner.{Person, Repo, Shift}
  alias Ecto.UUID

  import Ecto.{Query, Changeset}, warn: false

  require Logger

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type UUID
  @preloads [:available_shifts, :dispositioned_shifts, :dispositioned_griller_shifts]
  @join_person_availability "persons_available_shifts"
  @join_person_dispositioned_shift "persons_dispositioned_shifts"
  @join_griller_dispositioned_shift "persons_dispositioned_griller_shifts"

  @type t :: %__MODULE__{
               first_name: String.t,
               sure_name: String.t,
               email: nil | String.t,
               phone: nil | String.t,
               is_griller: boolean,
               available_shifts: list(Shiftplaner.Shift.t),
               dispositioned_shifts: list(Shiftplaner.Shift.t),
               dispositioned_griller_shifts: list(Shiftplaner.Shift.t)
             }
  schema "person" do
    field :first_name
    field :sure_name
    field :email
    field :phone
    field :is_griller, :boolean, default: false

    many_to_many :available_shifts, Shift, join_through: @join_person_availability, unique: true
    many_to_many :dispositioned_shifts,
                 Shift,
                 join_through: @join_person_dispositioned_shift, unique: true
    many_to_many :dispositioned_griller_shifts,
                 Shift,
                 join_through: @join_griller_dispositioned_shift, unique: true

    timestamps()
  end

  ##################################################################
  ####
  ####          Public API
  ####
  ##################################################################

  @spec add_person_as_available_for_shift(
          Shiftplaner.Person.t,
          Shiftplaner.Shift.t | list(Shiftplaner.Shift.t)
        ) :: Shiftplaner.Person.t | nil
  def add_person_as_available_for_shift(%Person{} = person, %Shift{} = shift) do
    person
    |> person_changeset(%{})
    |> put_assoc(:available_shifts, [shift])
    |> Repo.update()
    |> update_result()
  end

  def add_person_as_available_for_shift(%Person{} = person, list_of_shifts)
      when is_list(list_of_shifts) do
    Enum.each(list_of_shifts, &add_person_as_available_for_shift(person, &1))
  end

  @spec add_person_as_griller_to_shift(
          Shiftplaner.Person.t,
          Shiftplaner.Shift.t | list(Shiftplaner.Shift.t)
        ) :: Shiftplaner.Person.t | nil
  def add_person_as_griller_to_shift(%Person{is_griller: true} = person, %Shift{} = shift) do
    person
    |> person_changeset(%{})
    |> put_assoc(:dispositioned_griller_shifts, [shift])
    |> Repo.update()
    |> update_result()
  end

  def add_person_as_griller_to_shift(%Person{} = person, list_of_shifts)
      when is_list(list_of_shifts) do
    Enum.each(list_of_shifts, &add_person_as_griller_to_shift(person, &1))
  end

  @spec add_person_as_worker_to_shift(
          Shiftplaner.Person.t,
          Shiftplaner.Shift.t | list(Shiftplaner.Shift.t)
        ) :: Shiftplaner.Person.t | nil
  def add_person_as_worker_to_shift(%Person{} = person, %Shift{} = shift) do
    person
    |> person_changeset(%{})
    |> put_assoc(:dispositioned_shifts, [shift])
    |> Repo.update()
    |> update_result()
  end

  def add_person_as_worker_to_shift(%Person{} = person, list_of_shifts)
      when is_list(list_of_shifts) do
    Enum.each(list_of_shifts, &add_person_as_worker_to_shift(person, &1))
  end

  @spec change_person(Shiftplaner.Person.t) :: Ecto.Changeset.t
  def change_person(%Person{} = person) do
    person_changeset(person, %{})
  end

  @spec create_person(map) :: {:ok, Shiftplaner.Person.t} | {:error, Ecto.Changeset.t}
  def create_person(attrs) do
    %Person{}
    |> person_changeset(attrs)
    |> Repo.insert()
  end

  @spec delete_availability_for_worker_and_shift(
          Shiftplaner.Person.t,
          Shiftplaner.Shift.t
        ) :: {
               integer,
               nil | any
             }
  def delete_availability_for_worker_and_shift(%Person{} = person, %Shift{} = shift) do
    query = from a in @join_person_availability,
                 where: a.person_id == ^person.id and a.shift_id == ^shift.id
    Repo.delete_all(query)
  end

  @spec delete_griller_from_shift(Shiftplaner.Person.t, Shiftplaner.Shift.t) :: {integer, nil | any}
  def delete_griller_from_shift(%Person{} = person, %Shift{} = shift) do
    query = from a in @join_griller_dispositioned_shift,
                 where: a.person_id == ^person.id and a.shift_id == ^shift.id
    Repo.delete_all(query)
  end

  @spec delete_worker_from_shift(Shiftplaner.Person.t, Shiftplaner.Shift.t) :: {integer, nil | any}
  def delete_worker_from_shift(%Person{} = person, %Shift{} = shift) do
    query = from a in @join_person_dispositioned_shift,
                 where: a.person_id == ^person.id and a.shift_id == ^shift.id
    Repo.delete_all(query)
  end

  @spec delete_person(Shiftplaner.Person.t) :: {:ok, Shiftplaner.Person.t} | {
    :error,
    Ecto.Changeset.t
  }
  def delete_person(%Person{} = person) do
    person
    |> Repo.delete()
  end

  @spec get_person(String.t) :: {:ok, Shiftplaner.Person.t} | {:error, :could_not_fetch_person}
  def get_person(person_id) when is_binary(person_id) do
    Person
    |> where([p], p.id == ^person_id)
    |> Repo.one()
    |> Repo.preload([:available_shifts, :dispositioned_shifts, :dispositioned_griller_shifts])
    |> result_to_tuple()
  end

  @spec get_person!(String.t) :: Shiftplaner.Person.t | no_return
  def get_person!(person_id) when is_binary(person_id) do
    case get_person(person_id) do
      {:ok, person} -> person
      _ -> raise RuntimeError, message: "Could not fetch person for id: #{person_id}"
    end
  end

  @doc """
  List all persons

  Returns a list of ```Shiftplaner.Person```
  """
  @spec list_persons :: list(Shiftplaner.Person.t)
  def list_persons do
    Person
    |> order_by([p], [:is_griller, :sure_name])
    |> Repo.all()
    |> Repo.preload(@preloads)
  end

  @spec list_available_shift_ids_for_person_id(String.t) :: list(String.t)
  def list_available_shift_ids_for_person_id(person_id) do
    {:ok, p_id_bin} = UUID.dump(person_id)
    query = from a in @join_person_availability,
                 where: a.person_id == ^p_id_bin,
                 select: a.shift_id

    query
    |> Repo.all()
    |> Enum.map(
         fn (bin_id) ->
           {:ok, id} = UUID.load(bin_id)
           id
         end
       )
  end

  def list_available_shifts_for_person(%Person{} = person) do
    person.id
    |> list_available_shift_ids_for_person_id()
    |> Enum.map(fn shift_id -> Shiftplaner.get_shift!(shift_id)  end)
  end

  @spec remaining_number_of_available_shifts(Shiftplaner.Person.t) :: non_neg_integer()
  def remaining_number_of_available_shifts(%Person{} = person) do
    total_number_of_available_shifts(person) - length(person.dispositioned_shifts) - length(
      person.dispositioned_griller_shifts
    )
  end

  @spec total_number_of_available_shifts(Shiftplaner.Person.t) :: non_neg_integer()
  def total_number_of_available_shifts(%Person{} = person) do
    length(person.available_shifts)
  end

  @spec update_person(Shiftplaner.Person.t, map) :: {:ok, Shiftplaner.Person.t} | {
    :error,
    Ecto.Changeset.t
  }
  def update_person(%Person{} = person, attrs) when is_map(attrs)do
    person
    |> person_changeset(attrs)
    |> Repo.update()
  end

  @spec update_persons_availability_for_shifts(String.t, String.t, list(String.t)) :: {:ok}
  def update_persons_availability_for_shifts(person_id, event_id, lisf_of_selected_shift_ids)
      when is_binary(person_id) and is_list(lisf_of_selected_shift_ids) do
    selected_shift_ids = lisf_of_selected_shift_ids
                         |> MapSet.new()
    prev_selected_shifts =
      person_id
      |> list_available_shift_ids_for_person_id
      |> MapSet.new()

    delete_not_available_shifts(person_id, event_id, selected_shift_ids, prev_selected_shifts)
    insert_new_available_shifts(person_id, selected_shift_ids, prev_selected_shifts)

    {:ok}
  end

  ##################################################################
  ####
  ####          Private functions
  ####
  ##################################################################

  defp person_changeset(%Person{} = person, attrs) do
    person
    |> Repo.preload(@preloads)
    |> cast(attrs, [:first_name, :sure_name, :email, :phone, :is_griller])
    |> validate_required([:first_name, :sure_name])
  end

  defp update_result({:ok, %Person{} = person}) do
    Logger.debug fn ->
      "successfully updated person - #{person.id}: #{person.first_name} #{person.sure_name}"
    end
    person
  end

  defp update_result({:error, reason}) do
    Logger.warn fn -> "Could not update person - #{reason}" end
    nil
  end

  defp result_to_tuple(%Person{} = person) do
    {:ok, person}
  end

  defp result_to_tuple(_) do
    {:error, :could_not_fetch_person}
  end

  @spec insert_new_available_shifts(String.t, MapSet.t, MapSet.t) :: {integer, nil | [term]}
  defp insert_new_available_shifts(
         person_id,
         selected_shift_ids,
         prev_selected_shifts
       )  do
    list_of_inserts =
      selected_shift_ids
      |> MapSet.difference(prev_selected_shifts)
      |> MapSet.to_list()
      |> map_list_to_insert_map(person_id)

    Repo.insert_all(@join_person_availability, list_of_inserts)
  end

  defp map_list_to_insert_map(list_of_shifts, person_id) when is_list(list_of_shifts) do
    list_of_shifts
    |> Enum.map(
         fn (shift_id) ->
           {:ok, s_id_bin} = UUID.dump(shift_id)
           {:ok, p_id_bin} = UUID.dump(person_id)
           %{"shift_id" => s_id_bin, "person_id" => p_id_bin}
         end
       )
  end

  @spec delete_not_available_shifts(String.t, String.t, MapSet.t, MapSet.t) :: {
                                                                                 integer,
                                                                                 nil | [term]
                                                                               }
  defp delete_not_available_shifts(
         person_id,
         event_id,
         selected_shift_ids,
         prev_selected_shifts
       ) do

    list_of_shifts_for_event = event_id
                               |> Shiftplaner.list_all_shifts_for_event()
                               |> map_list_to_bin_uuid_list

    list_of_shifts_to_remove =
      prev_selected_shifts
      |> MapSet.difference(selected_shift_ids)
      |> MapSet.to_list()
      |> map_list_to_bin_uuid_list()

    {:ok, p_bin_id} = UUID.dump(person_id)
    delete_query = from a in @join_person_availability,
                        where: a.person_id == ^p_bin_id
                               and a.shift_id in ^list_of_shifts_to_remove
                        and a.shift_id in ^list_of_shifts_for_event
    Repo.delete_all(delete_query)
  end

  defp map_list_to_bin_uuid_list(list_of_shift_ids) when is_list(list_of_shift_ids) do
    list_of_shift_ids
    |> Enum.map(
         fn shift_id ->
           {:ok, id} = UUID.dump(shift_id)
           id
         end
       )
  end
end
