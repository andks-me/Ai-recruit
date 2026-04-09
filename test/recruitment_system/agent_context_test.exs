defmodule RecruitmentSystem.AgentContextTest do
  use ExUnit.Case, async: true

  alias RecruitmentSystem.Agents.AgentContext

  test "cookie_header/1 joins cookies" do
    header = AgentContext.cookie_header(%{"li_at" => "TOKEN", "a" => "1"})
    assert header == "a=1; li_at=TOKEN"
  end

  test "new/2 requires non-empty li_at" do
    assert {:error, {:missing_cookie, "li_at"}} = AgentContext.new(%{"foo" => "bar"})
    assert {:error, {:missing_cookie, "li_at"}} = AgentContext.new(%{"li_at" => "   "})
  end
end

