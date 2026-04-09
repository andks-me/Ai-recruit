defmodule RecruitmentSystem.Agents.LinkedInAgent do
  @moduledoc false

  alias RecruitmentSystem.Agents.AgentContext
  alias RecruitmentSystem.LinkedIn.Client

  @type result ::
          {:ok, term()}
          | {:error, :auth_expired}
          | {:error, term()}

  @spec fetch_profile_html(AgentContext.t(), binary(), keyword()) :: result()
  def fetch_profile_html(%AgentContext{} = ctx, profile_url, opts \\ []) when is_binary(profile_url) do
    case Client.get(ctx, profile_url, opts) do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, :auth_expired} -> {:error, :auth_expired}
      {:error, other} -> {:error, other}
    end
  end
end

