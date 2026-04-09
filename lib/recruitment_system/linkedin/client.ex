defmodule RecruitmentSystem.LinkedIn.Client do
  @moduledoc false

  alias RecruitmentSystem.Agents.AgentContext

  @default_user_agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"

  @type http_status :: non_neg_integer()

  @spec get(AgentContext.t(), binary(), keyword()) ::
          {:ok, %{status: http_status(), headers: list(), body: binary()}} | {:error, term()}
  def get(%AgentContext{} = ctx, url, opts \\ []) when is_binary(url) do
    request(:get, ctx, url, "", opts)
  end

  @spec request(atom(), AgentContext.t(), binary(), binary(), keyword()) ::
          {:ok, %{status: http_status(), headers: list(), body: binary()}} | {:error, term()}
  def request(method, %AgentContext{} = ctx, url, body, opts)
      when is_atom(method) and is_binary(url) and is_binary(body) do
    headers = build_headers(ctx, Keyword.get(opts, :headers, []))
    http_opts = build_http_opts(ctx, opts)
    req = {to_charlist(url), headers, ~c"text/html", body}

    # We want to observe 30x (redirect-to-login) instead of auto-following.
    req_opts = [body_format: :binary, autoredirect: false]

    case :httpc.request(method, req, http_opts, req_opts) do
      {:ok, {{_version, status, _reason}, resp_headers, resp_body}} ->
        resp = %{status: status, headers: resp_headers, body: resp_body}

        case classify_auth(resp) do
          :ok -> {:ok, resp}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec build_headers(AgentContext.t(), list()) :: list()
  def build_headers(%AgentContext{} = ctx, extra_headers) when is_list(extra_headers) do
    cookie = AgentContext.cookie_header(ctx.cookies)
    ua = ctx.user_agent || @default_user_agent

    base =
      [
        {~c"user-agent", to_charlist(ua)},
        {~c"accept", ~c"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
        {~c"accept-language", ~c"en-US,en;q=0.9"},
        {~c"cookie", to_charlist(cookie)}
      ]
      |> merge_headers(extra_headers)

    base
  end

  defp merge_headers(base, extra) do
    # extra headers overwrite base (case-insensitive)
    extra_map =
      extra
      |> Enum.reduce(%{}, fn
        {k, v}, acc when is_binary(k) and is_binary(v) ->
          Map.put(acc, String.downcase(k), {to_charlist(k), to_charlist(v)})

        {k, v}, acc when is_list(k) and is_list(v) ->
          Map.put(acc, k |> to_string() |> String.downcase(), {k, v})

        _, acc ->
          acc
      end)

    base_map =
      base
      |> Enum.reduce(%{}, fn {k, v}, acc ->
        Map.put(acc, k |> to_string() |> String.downcase(), {k, v})
      end)

    base_map
    |> Map.merge(extra_map)
    |> Map.values()
  end

  defp build_http_opts(%AgentContext{} = ctx, opts) do
    timeout = Keyword.get(opts, :timeout, 30_000)

    http_opts = [timeout: timeout, connect_timeout: timeout]

    case ctx.proxy || Keyword.get(opts, :proxy) do
      nil ->
        http_opts

      proxy when is_binary(proxy) ->
        # expects "http://host:port" or "host:port"
        http_opts ++ [proxy: proxy_to_charlist(proxy)]
    end
  end

  defp proxy_to_charlist(proxy) do
    proxy
    |> String.replace_prefix("http://", "")
    |> String.replace_prefix("https://", "")
    |> to_charlist()
  end

  @spec classify_auth(%{status: http_status(), headers: list(), body: binary()}) ::
          :ok | {:error, :auth_expired}
  def classify_auth(%{status: status, headers: headers, body: body})
      when is_integer(status) and is_list(headers) and is_binary(body) do
    cond do
      status in [401, 403] ->
        {:error, :auth_expired}

      status in [301, 302, 303, 307, 308] and redirect_to_login?(headers) ->
        {:error, :auth_expired}

      login_page?(body) ->
        {:error, :auth_expired}

      true ->
        :ok
    end
  end

  defp redirect_to_login?(headers) do
    location =
      headers
      |> Enum.find_value(fn
        {k, v} when is_list(k) and is_list(v) ->
          if String.downcase(to_string(k)) == "location", do: to_string(v), else: nil

        _ ->
          nil
      end)

    case location do
      nil -> false
      loc -> String.contains?(loc, "/login") or String.contains?(loc, "checkpoint")
    end
  end

  defp login_page?(body) do
    # heuristic markers; keep broad to catch localized login pages
    String.contains?(body, "linkedin.com/login") or
      String.contains?(body, "Sign in") and String.contains?(body, "session_key") or
      String.contains?(body, "checkpoint/challenge")
  end
end

