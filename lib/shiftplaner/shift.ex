defmodule Shiftplaner.Shift do
  @moduledoc false

  alias Shiftplaner.{Person, Repo, Shift}
  alias Ecto.UUID

  import Ecto.{Query, Changeset}, warn: false

  use Ecto.Schema

  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type UUID
  @preloads [:day, :available_persons, :dispositioned_persons, :dispositioned_griller]
  @jointable_dispositioned_worker_shifts "persons_dispositioned_shifts"
  @jointable_dispositioned_griller_shifts "persons_dispositioned_griller_shifts"

  @type t :: %__MODULE__{
               worker_needed: non_neg_integer(),
               griller_needed: non_neg_integer(),
               start_time: Time.t,
               end_time: Time.t,
               day: Shiftplaner.Day.t,
               available_persons: list(Shiftplaner.Person.t),
               dispositioned_persons: list(Shiftplaner.Person.t),
               dispositioned_griller: list(Shiftplaner.Person.t)
             }
  schema "shift" do
    field :worker_needed, :integer
    field :griller_needed, :integer, default: 1
    field :start_time, :time
    field :end_time, :time

    belongs_to :day, Shiftplaner.Day

    many_to_many :available_persons,
                 Person,
                 join_through: "persons_available_shifts", unique: true
    many_to_many :dispositioned_persons,
                 Person,
                 join_through: "persons_dispositioned_shifts", on_replace: :delete, unique: true
    many_to_many :dispositioned_griller,
                 Person,
                 join_through: "persons_dispositioned_griller_shifts",
                 on_replace: :delete,
                 unique: true

    timestamps()
  end

  ##################################################################
  ####
  ####          Public API
  ####
  ##################################################################

  @spec change_shift(Shiftplaner.Shift.t) :: Ecto.Changeset.t
  def change_shift(%Shift{} = shift) do
    shift_changeset(shift, %{})
  end

  @spec create_shift(map) :: {:ok, Shiftplaner.Shift.t} | {:error, Ecto.Changeset.t}
  def create_shift(attrs) do
    %Shift{}
    |> shift_changeset(attrs)
    |> Repo.insert()
  end

  @spec delete_shift(Shiftplaner.Shift.t) :: {:ok, Shiftplaner.Shift.t} | {:error, Ecto.Changeset.t}
  def delete_shift(%Shift{} = shift)  do
    shift
    |> Repo.delete()
  end

  @spec disposition_worker_to_shift(
          Shiftplaner.Shift.t,
          Shiftplaner.Person.t | list(Shiftplaner.Pers)
        ) :: Shiftplaner.Shift.t | no_return
  def disposition_worker_to_shift(%Shift{} = shift, %Person{} = person) do
    shift
    |> shift_changeset(%{})
    |> put_assoc(:dispositioned_persons, [person])
    |> Repo.update!()
  end

  @spec disposition_workers_to_shift(String.t, list(String.t)) :: {integer, nil | [term]}
  def disposition_workers_to_shift(shift_id, list_of_workers)
      when is_binary(shift_id) and is_list(list_of_workers) do
    shift_id
    |> delete_all_workers_from_shift()
    |> insert_all_workers_for_shift(list_of_workers)
  end

  @spec disposition_grillers_to_shift(String.t, list(String.t)) :: {integer, nil | [term]}
  def disposition_grillers_to_shift(shift_id, list_of_griller)
      when is_binary(shift_id) and is_list(list_of_griller) do
    shift_id
    |> delete_all_grillers_from_shift()
    |> insert_all_grillers_for_shift(list_of_griller)
  end

  @spec dispositon_griller_to_shift(
          Shiftplaner.Shift.t,
          Shiftplaner.Person.t
        ) :: Shiftplaner.Shift.t | no_return
  def dispositon_griller_to_shift(%Shift{} = shift, %Person{is_griller: true} = griller) do
    shift
    |> shift_changeset(%{})
    |> put_assoc(:dispositioned_griller, [griller])
    |> Repo.update!()
  end

  @spec get_shift(String.t) :: {:ok, Shiftplaner.Shift.t} | {:error, :could_not_fetch_shift}
  def get_shift(id) when is_binary(id) do
    Shift
    |> where([s], s.id == ^id)
    |> Repo.one
    |> Repo.preload(@preloads)
    |> result_to_tuple()
  end

  @spec get_shift!(String.t) :: Shiftplaner.Shift.t | no_return
  def get_shift!(id) when is_binary(id) do
    case get_shift(id) do
      {:ok, %Shift{} = shift} -> shift
      _ -> raise RuntimeError, message: "Could not fetch shift with id: #{id}"
    end
  end

  @spec list_available_worker_for_shift(Shiftplaner.Shift.t) :: list(Shiftplaner.Person.t)
  def list_available_worker_for_shift(%Shift{} = shift) do
    Shift
    |> where([s], s.id == ^shift.id)
    |> Repo.one()
    |> Repo.preload(:available_persons)
    |> Map.get(:available_persons)
  end

  @spec list_available_griller_for_shift(Shiftplaner.Shift.t) :: list(Shiftplaner.Person.t)
  def list_available_griller_for_shift(%Shift{griller_needed: 0}), do: []
  def list_available_griller_for_shift(%Shift{} = shift) do
    shift
    |> list_available_worker_for_shift()
    |> Enum.filter(fn (person) -> person.is_griller end)
  end

  @spec list_dispositioned_worker_for_shift(Shiftplaner.Shift.t) :: list(Shiftplaner.Person.t)
  def list_dispositioned_worker_for_shift(%Shift{} = shift) do
    Shift
    |> where([s], s.id == ^shift.id)
    |> Repo.one()
    |> repo_one_nil_to_empty_shift()
    |> Repo.preload(:dispositioned_persons)
    |> Map.get(:dispositioned_persons)
  end

  @spec list_dispositioned_griller_for_shift(Shiftplaner.Shift.t) :: list(Shiftplaner.Person.t)
  def list_dispositioned_griller_for_shift(%Shift{griller_needed: 0}), do: []
  def list_dispositioned_griller_for_shift(%Shift{} = shift) do
    Shift
    |> where([s], s.id == ^shift.id)
    |> Repo.one()
    |> repo_one_nil_to_empty_shift()
    |> Repo.preload(:dispositioned_griller)
    |> Map.get(:dispositioned_griller)
  end

  @spec list_shifts :: list(Shiftplaner.Shift.t)
  def list_shifts do
    Shift
    |> Repo.all()
    |> Repo.preload(:day)
  end

  @spec list_shifts_for_day(String.t) :: list(Shiftplaner.Shift.t)
  def list_shifts_for_day(day_id) when is_binary(day_id) do
    Shift
    |> where([s], s.day_id == ^day_id)
    |> Repo.all()
    |> Repo.preload(@preloads)
  end

  @spec needs_worker?(Shiftplaner.Shift.t) :: boolean
  def needs_worker?(%Shift{} = shift) do
    shift.worker_needed > length(shift.dispositioned_persons)
  end

  @spec needs_griller?(Shiftplaner.Shift.t) :: boolean
  def needs_griller?(%Shift{} = shift) do
    shift.griller_needed > length(shift.dispositioned_griller)
  end

  @spec needs_personal?(Shiftplaner.Shift.t) :: boolean
  def needs_personal?(%Shift{} = shift) do
    needs_worker?(shift) || needs_griller?(shift)
  end

  @spec number_of_workers_needed(Shiftplaner.Shift.t) :: non_neg_integer()
  def number_of_workers_needed(%Shift{} = shift) do
    shift.worker_needed - length(shift.dispositioned_persons)
  end

  @spec number_of_grillers_needed(Shiftplaner.Shift.t) :: non_neg_integer()
  def number_of_grillers_needed(%Shift{} = shift) do
    shift.griller_needed - length(shift.dispositioned_griller)
  end

  @spec number_of_personal_needed(Shiftplaner.Shift.t) :: non_neg_integer()
  def number_of_personal_needed(%Shift{} = shift) do
    number_of_workers_needed(shift) + number_of_grillers_needed(shift)
  end

  @spec update_shift(Shiftplaner.Shift.t, map) :: {:ok, Shiftplaner.Shift.t} | {
    :error,
    Ecto.Changeset.t
  }
  def update_shift(%Shift{} = shift, attrs) when is_map(attrs) do
    shift
    |> shift_changeset(attrs)
    |> Repo.update()
  end

  ##################################################################
  ####
  ####          Private functions
  ####
  ##################################################################

  defp delete_all_grillers_from_shift(shift_id) when is_binary(shift_id) do
    {:ok, bin_shift_id} = UUID.dump(shift_id)
    query = from a in @jointable_dispositioned_griller_shifts,
                 where: a.shift_id == ^bin_shift_id
    Repo.delete_all(query)
    shift_id
  end

  defp delete_all_workers_from_shift(shift_id) when is_binary(shift_id) do
    {:ok, bin_shift_id} = UUID.dump(shift_id)
    query = from a in @jointable_dispositioned_worker_shifts,
                 where: a.shift_id == ^bin_shift_id
    Repo.delete_all(query)
    shift_id
  end

  defp insert_all_grillers_for_shift(shift_id, list_of_grillers)
       when is_binary(shift_id) and is_list(list_of_grillers) do
    list_of_inserts =
      list_of_grillers
      |> Enum.map(
           fn griller_id ->
             {:ok, w_bin_id} = UUID.dump(griller_id)
             {:ok, s_bin_id} = UUID.dump(shift_id)
             %{"shift_id" => s_bin_id, "person_id" => w_bin_id}
           end
         )
    Repo.insert_all(
      @jointable_dispositioned_griller_shifts,
      list_of_inserts,
      on_conflict: :replace_all,
      conflict_target: [:person_id, :shift_id]
    )
  end

  defp insert_all_workers_for_shift(shift_id, list_of_workers)
       when is_binary(shift_id) and is_list(list_of_workers) do
    list_of_inserts =
      list_of_workers
      |> Enum.map(
           fn worker_id ->
             {:ok, w_bin_id} = UUID.dump(worker_id)
             {:ok, s_bin_id} = UUID.dump(shift_id)
             %{"shift_id" => s_bin_id, "person_id" => w_bin_id}
           end
         )
    Repo.insert_all(
      @jointable_dispositioned_worker_shifts,
      list_of_inserts,
      on_conflict: :replace_all,
      conflict_target: [:person_id, :shift_id]
    )
  end

  defp shift_changeset(%Shift{} = shift, attrs) do
    shift
    |> Repo.preload([:available_persons, :dispositioned_persons])
    |> cast(attrs, [:worker_needed, :griller_needed, :start_time, :end_time, :day_id])
    |> validate_required([:worker_needed, :griller_needed, :start_time, :end_time, :day_id])
  end

  defp repo_one_nil_to_empty_shift(result) when is_nil(result) do
    %Shift{}
  end

  defp repo_one_nil_to_empty_shift(%Shift{} = shift) do
    shift
  end

  defp result_to_tuple(%Shift{} = shift) do
    {:ok, shift}
  end

  defp result_to_tuple(_) do
    {:error, :could_not_fetch_shift}
  end

  ##################################################################
  ####
  ####          Protocol implementations
  ####
  ##################################################################

  defimpl String.Chars, for: Shift do
    def to_string(%Shift{} = shift) do
      "Shift from #{shift.start_time} to #{shift.end_time}"
    end
  end
end
