import Config

config :recruitment_system,
  ecto_repos: []

config :recruitment_system, RecruitmentSystem.Scheduler,
  jobs: [
    github_search: [
      schedule: "0 * * * *",
      task: {RecruitmentSystem.Agents.GitHubAgent, :search_candidates, ["elixir"]}
    ]
  ]

config :oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10, outreach: 5]

import_config "#{config_env()}.exs"
