defmodule Shiftplaner.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Shiftplaner.Repo, [])
    ]

    opts = [
      strategy: :one_for_one,
      name: Shiftplaner.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end