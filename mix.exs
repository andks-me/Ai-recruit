defmodule RecruitmentSystem.MixProject do
  use Mix.Project

  def project do
    [
      app: :recruitment_system,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RecruitmentSystem.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:quantum, "~> 3.4"},
      {:crontab, "~> 1.1"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.19"},
      {:plug_cowboy, "~> 2.6"},
      {:floki, "~> 0.34"},
      {:oban, "~> 2.13"}
    ]
  end
end
