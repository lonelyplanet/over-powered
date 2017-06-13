defmodule DummyApp.HealthCheckTest do
  use DummyApp.ConnCase, async: true

  test "GET /health-check", %{conn: conn} do
    payload =
      conn
      |> get("/health-check")
      |> json_response(200)

    assert payload["data"]["attributes"]["contact-info"]["service-owner-slackid"]
    assert payload["data"]["attributes"]["contact-info"]["slack-channel"]
    assert payload["data"]["attributes"]["docker-image"]
    assert payload["data"]["attributes"]["github-commit"]
    assert payload["data"]["attributes"]["github-repo-name"]
    assert payload["data"]["attributes"]["lp-service-group-id"]
    assert payload["data"]["attributes"]["lp-service-id"]
    assert payload["data"]["id"] == "dummy-app"
    assert payload["data"]["type"] == "op-service"
  end
end
