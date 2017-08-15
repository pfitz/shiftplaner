use Mix.Config

config :shiftplaner, ecto_repos: [Shiftplaner.Repo]

import_config "#{Mix.env}.exs"