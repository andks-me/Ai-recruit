defmodule RecruitmentSystem.Agents.AgentContext do
  @moduledoc false

  @enforce_keys [:cookies]
  defstruct cookies: %{},
            user_agent: nil,
            proxy: nil

  @type cookie_name :: binary()
  @type cookie_value :: binary()
  @type cookies :: %{optional(cookie_name) => cookie_value}

  @type t :: %__MODULE__{
          cookies: cookies(),
          user_agent: binary() | nil,
          proxy: binary() | nil
        }

  @spec new(cookies() | nil, keyword()) :: {:ok, t()} | {:error, term()}
  def new(cookies, opts \\ []) do
    cookies = normalize_cookies(cookies || %{})

    with :ok <- validate_required_cookie(cookies, "li_at"),
         :ok <- validate_li_at_format(cookies["li_at"]) do
      {:ok,
       %__MODULE__{
         cookies: cookies,
         user_agent: Keyword.get(opts, :user_agent),
         proxy: Keyword.get(opts, :proxy)
       }}
    end
  end

  @spec cookie_header(cookies()) :: binary()
  def cookie_header(cookies) when is_map(cookies) do
    cookies
    |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.map_join("; ", fn {k, v} -> "#{k}=#{v}" end)
  end

  @spec normalize_cookies(term()) :: cookies()
  def normalize_cookies(cookies) when is_map(cookies) do
    cookies
    |> Enum.reduce(%{}, fn
      {k, v}, acc when is_binary(k) and is_binary(v) ->
        Map.put(acc, String.downcase(k), v)

      {k, v}, acc ->
        acc
        |> maybe_put_cookie(k, v)
    end)
  end

  def normalize_cookies(_), do: %{}

  defp maybe_put_cookie(acc, k, v) when is_atom(k) and is_binary(v),
    do: Map.put(acc, k |> Atom.to_string() |> String.downcase(), v)

  defp maybe_put_cookie(acc, k, v) when is_binary(k) and is_atom(v),
    do: Map.put(acc, String.downcase(k), Atom.to_string(v))

  defp maybe_put_cookie(acc, _k, _v), do: acc

  defp validate_required_cookie(cookies, name) do
    case Map.get(cookies, name) do
      v when is_binary(v) ->
        if String.trim(v) == "", do: {:error, {:missing_cookie, name}}, else: :ok

      _ -> {:error, {:missing_cookie, name}}
    end
  end

  # Accept either hex or base64-ish tokens (LinkedIn li_at is often a long opaque token).
  # We keep this intentionally permissive: hard rejects only obviously invalid values.
  defp validate_li_at_format(li_at) when is_binary(li_at) do
    li_at = String.trim(li_at)

    cond do
      li_at == "" ->
        {:error, :invalid_li_at}

      hex?(li_at) ->
        :ok

      base64ish?(li_at) ->
        :ok

      true ->
        {:error, :invalid_li_at_format}
    end
  end

  defp validate_li_at_format(_), do: {:error, :invalid_li_at}

  defp hex?(s), do: String.match?(s, ~r/^[0-9a-fA-F]+$/) and byte_size(s) >= 16

  defp base64ish?(s) do
    # allow base64/base64url characters and optional '=' padding
    String.match?(s, ~r/^[A-Za-z0-9+\/_-]+={0,2}$/) and byte_size(s) >= 16
  end
end

