defmodule RecruitmentSystem.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:recruitment_system, :http_port, 4000)

    children = [
      {Plug.Cowboy, scheme: :http, plug: RecruitmentSystem.Web.Router, options: [port: port]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: RecruitmentSystem.Supervisor)
  end
end

