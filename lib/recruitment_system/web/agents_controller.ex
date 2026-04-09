defmodule RecruitmentSystem.Web.AgentsController do
  @moduledoc false

  alias RecruitmentSystem.Agents.AgentContext
  alias RecruitmentSystem.LinkedIn.SessionStore

  @spec create(map()) :: {:ok, map()} | {:error, term()}
  def create(%{} = params) do
    # minimal contract:
    # {
    #   "agent_type": "linkedin",
    #   "user_id": "u_123",
    #   "linkedin_auth": { "cookies": { "li_at": "...", ... }, "user_agent": "...", "proxy": "..." }
    # }
    with "linkedin" <- Map.get(params, "agent_type", "linkedin"),
         {:ok, user_id} <- validate_user_id(Map.get(params, "user_id")),
         {:ok, cookies, opts} <- extract_linkedin_auth(params),
         {:ok, %AgentContext{} = ctx} <- AgentContext.new(cookies, opts),
         :ok <- SessionStore.put(user_id, ctx) do
      {:ok, %{status: "OK", agent_type: "linkedin", user_id: user_id}}
    else
      nil ->
        {:error, {:validation, "user_id is required"}}

      {:error, :invalid_user_id} ->
        {:error, {:validation, "user_id is required"}}

      {:error, {:missing_cookie, "li_at"}} ->
        {:error, {:validation, "linkedin_auth.cookies.li_at is required"}}

      {:error, :invalid_li_at} ->
        {:error, {:validation, "li_at must be a non-empty string"}}

      {:error, :invalid_li_at_format} ->
        {:error, {:validation, "li_at has invalid format (expected hex/base64-like token)"}}

      {:error, {:validation, _} = e} ->
        {:error, e}

      other ->
        {:error, other}
    end
  end

  def create(_), do: {:error, :bad_request}

  defp validate_user_id(user_id) when is_binary(user_id) do
    user_id = String.trim(user_id)
    if user_id == "", do: {:error, :invalid_user_id}, else: {:ok, user_id}
  end

  defp validate_user_id(_), do: {:error, :invalid_user_id}

  defp extract_linkedin_auth(%{"linkedin_auth" => %{} = la}) do
    cookies = Map.get(la, "cookies") || Map.get(la, "cookies", %{})
    li_at = Map.get(la, "li_at")

    cookies =
      cond do
        is_map(cookies) ->
          cookies

        true ->
          %{}
      end

    cookies =
      if is_binary(li_at) and String.trim(li_at) != "" do
        Map.put_new(cookies, "li_at", li_at)
      else
        cookies
      end

    opts =
      []
      |> maybe_put_opt(:user_agent, Map.get(la, "user_agent"))
      |> maybe_put_opt(:proxy, Map.get(la, "proxy"))

    {:ok, cookies, opts}
  end

  defp extract_linkedin_auth(%{"cookies" => %{} = cookies} = params) do
    # allow legacy: {cookies: {...}, user_agent: "..."}
    opts =
      []
      |> maybe_put_opt(:user_agent, Map.get(params, "user_agent"))
      |> maybe_put_opt(:proxy, Map.get(params, "proxy"))

    {:ok, cookies, opts}
  end

  defp extract_linkedin_auth(_), do: {:error, {:validation, "linkedin_auth or cookies is required"}}

  defp maybe_put_opt(opts, _k, v) when is_nil(v) or v == "", do: opts
  defp maybe_put_opt(opts, k, v) when is_binary(v), do: Keyword.put(opts, k, v)
  defp maybe_put_opt(opts, _k, _v), do: opts
end

