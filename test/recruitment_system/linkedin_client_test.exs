defmodule RecruitmentSystem.LinkedInClientTest do
  use ExUnit.Case, async: true

  alias RecruitmentSystem.Agents.AgentContext
  alias RecruitmentSystem.LinkedIn.Client

  test "classify_auth returns auth_expired on 401/403" do
    assert {:error, :auth_expired} =
             Client.classify_auth(%{status: 401, headers: [], body: ""})

    assert {:error, :auth_expired} =
             Client.classify_auth(%{status: 403, headers: [], body: ""})
  end

  test "classify_auth returns auth_expired on redirect to login" do
    headers = [{~c"location", ~c"https://www.linkedin.com/login"}]

    assert {:error, :auth_expired} =
             Client.classify_auth(%{status: 302, headers: headers, body: ""})
  end

  test "build_headers includes cookie and user-agent" do
    {:ok, ctx} = AgentContext.new(%{"li_at" => "ZHVtbXktbG9uZy10b2tlbi0xMjM0NTY3ODkw"}, user_agent: "UA")
    headers = Client.build_headers(ctx, [])

    assert Enum.any?(headers, fn {k, _v} -> to_string(k) == "user-agent" end)
    assert Enum.any?(headers, fn {k, v} ->
             to_string(k) == "cookie" and to_string(v) =~ "li_at=ZHVtbXktbG9uZy10b2tlbi0xMjM0NTY3ODkw"
           end)
  end
end

