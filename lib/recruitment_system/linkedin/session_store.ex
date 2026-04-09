defmodule RecruitmentSystem.LinkedIn.SessionStore do
  @moduledoc false

  alias RecruitmentSystem.Agents.AgentContext

  @table :recruitment_system_linkedin_sessions

  @spec put(binary(), AgentContext.t()) :: :ok | {:error, term()}
  def put(user_id, %AgentContext{} = ctx) when is_binary(user_id) do
    with {:ok, dets} <- ensure_open(),
         {:ok, blob} <- encrypt(term_payload(ctx)) do
      :ok = :dets.insert(dets, {user_id, blob})
      :ok
    end
  end

  @spec get(binary()) :: {:ok, AgentContext.t()} | {:error, :not_found} | {:error, term()}
  def get(user_id) when is_binary(user_id) do
    with {:ok, dets} <- ensure_open() do
      case :dets.lookup(dets, user_id) do
        [{^user_id, blob}] ->
          with {:ok, payload} <- decrypt(blob) do
            {:ok, payload_to_ctx(payload)}
          end

        [] ->
          {:error, :not_found}
      end
    end
  end

  @spec revoke(binary()) :: :ok | {:error, term()}
  def revoke(user_id) when is_binary(user_id) do
    with {:ok, dets} <- ensure_open() do
      :ok = :dets.delete(dets, user_id)
      :ok
    end
  end

  defp ensure_open do
    path = Path.join(:code.priv_dir(:recruitment_system) |> to_string(), "linkedin_sessions.dets")

    case :dets.open_file(@table, type: :set, file: to_charlist(path)) do
      {:ok, _} = ok -> ok
      {:error, {:already_exists, _}} -> {:ok, @table}
      other -> other
    end
  end

  defp term_payload(%AgentContext{} = ctx) do
    %{
      cookies: ctx.cookies,
      user_agent: ctx.user_agent,
      proxy: ctx.proxy,
      updated_at: DateTime.utc_now()
    }
  end

  defp payload_to_ctx(%{cookies: cookies} = payload) do
    {:ok, ctx} =
      AgentContext.new(cookies, user_agent: Map.get(payload, :user_agent), proxy: Map.get(payload, :proxy))

    ctx
  end

  defp encrypt(term) do
    key = master_key!()
    iv = :crypto.strong_rand_bytes(12)
    plaintext = :erlang.term_to_binary(term)
    {ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, "", true)
    {:ok, iv <> tag <> ciphertext}
  rescue
    e -> {:error, e}
  end

  defp decrypt(blob) when is_binary(blob) do
    key = master_key!()

    with <<iv::binary-12, tag::binary-16, ciphertext::binary>> <- blob,
         plaintext when is_binary(plaintext) <-
           :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, "", tag, false) do
      {:ok, :erlang.binary_to_term(plaintext)}
    else
      _ -> {:error, :decrypt_failed}
    end
  rescue
    e -> {:error, e}
  end

  defp master_key! do
    # 32 bytes, base64-encoded
    case System.get_env("RECRUITMENT_SYSTEM_COOKIE_KEY_B64") do
      nil ->
        raise "missing env RECRUITMENT_SYSTEM_COOKIE_KEY_B64 (32 bytes base64)"

      b64 ->
        case Base.decode64(b64) do
          {:ok, key} when byte_size(key) == 32 -> key
          _ -> raise "invalid RECRUITMENT_SYSTEM_COOKIE_KEY_B64 (expected base64 of 32 bytes)"
        end
    end
  end
end

