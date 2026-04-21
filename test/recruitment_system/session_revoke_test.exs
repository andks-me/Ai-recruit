defmodule RecruitmentSystem.SessionRevokeTest do
  use ExUnit.Case, async: true

  alias RecruitmentSystem.Agents.AgentContext
  alias RecruitmentSystem.LinkedIn.SessionStore

  test "revoke deletes session" do
    {:ok, ctx} = AgentContext.new(%{"li_at" => "ZHVtbXktbG9uZy10b2tlbi0xMjM0NTY3ODkw"})
    assert :ok = SessionStore.put("u_test", ctx)
    assert {:ok, _} = SessionStore.get("u_test")
    assert :ok = SessionStore.revoke("u_test")
    assert {:error, :not_found} = SessionStore.get("u_test")
  end
end

