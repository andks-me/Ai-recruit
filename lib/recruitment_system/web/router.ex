defmodule RecruitmentSystem.Web.Router do
  @moduledoc false

  use Plug.Router

  plug Plug.Logger
  plug :match
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug :dispatch

  post "/api/v1/agents/create" do
    case RecruitmentSystem.Web.AgentsController.create(conn.body_params) do
      {:ok, resp} ->
        send_json(conn, 201, resp)

      {:error, {:validation, msg}} ->
        send_json(conn, 422, %{error: msg})

      {:error, :bad_request} ->
        send_json(conn, 400, %{error: "bad_request"})

      {:error, other} ->
        send_json(conn, 500, %{error: "internal_error", reason: inspect(other)})
    end
  end

  match _ do
    send_json(conn, 404, %{error: "not_found"})
  end

  defp send_json(conn, status, map) do
    body = Jason.encode!(map)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, body)
  end
end

