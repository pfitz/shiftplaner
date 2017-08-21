defmodule Shiftplaner.Shift do
  @moduledoc false

  alias Shiftplaner.{Person, Repo, Shift}

  import Ecto.{Query, Changeset}, warn: false

  use Ecto.Schema

  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type Ecto.UUID


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
                 join_through: "persons_dispositioned_shifts", unique: true
    many_to_many :dispositioned_griller,
                 Person,
                 join_through: "persons_dispositioned_griller_shifts", unique: true

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

  @spec create_shift(map) :: Shiftplaner.Shift.t | nil
  def create_shift(attrs) do
    %Shift{}
    |> shift_changeset(attrs)
    |> Repo.insert()
    |> insert_result()
  end

  @spec disposition_worker_to_shift(
          Shiftplaner.Shift.t,
          Shiftplaner.Person.t
        ) :: Shiftplaner.Shift.t | no_return
  def disposition_worker_to_shift(%Shift{} = shift, %Person{} = person) do
    shift
    |> shift_changeset(%{})
    |> put_assoc(:dispositioned_persons, [person])
    |> Repo.update!()
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
    |> Repo.all
    |> Repo.preload(:day)
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

  ##################################################################
  ####
  ####          Private functions
  ####
  ##################################################################

  defp shift_changeset(%Shift{} = shift, attrs) do
    shift
    |> Repo.preload([:available_persons, :dispositioned_persons])
    |> cast(attrs, [:worker_needed, :griller_needed, :start_time, :end_time])
    |> validate_required([:worker_needed, :griller_needed, :start_time, :end_time])
  end

  defp insert_result({:ok, %Shift{} = shift}) do
    Logger.debug fn -> "successfully inserted shift - #{shift}" end
    shift
  end

  defp insert_result({:error, reason}) do
    Logger.warn fn -> "Could not insert Shift - #{reason}" end
    nil
  end

  defp repo_one_nil_to_empty_shift(result) when is_nil(result) do
    %Shift{}
  end

  defp repo_one_nil_to_empty_shift(%Shift{} = shift) do
    shift
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
