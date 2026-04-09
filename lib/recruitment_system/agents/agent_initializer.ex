defmodule RecruitmentSystem.Agents.AgentInitializer do
  @moduledoc false

  alias RecruitmentSystem.Agents.AgentContext

  @type agent_module :: module()

  @spec init_linkedin_agent(map(), keyword()) ::
          {:ok, {agent_module(), AgentContext.t()}} | {:error, term()}
  def init_linkedin_agent(%{} = cookies, opts \\ []) do
    case AgentContext.new(cookies, opts) do
      {:ok, ctx} -> {:ok, {RecruitmentSystem.Agents.LinkedInAgent, ctx}}
      {:error, reason} -> {:error, reason}
    end
  end
end

