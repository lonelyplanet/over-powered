defmodule DummyApp.MetricsTest do
  use DummyApp.ConnCase, async: true

  test "GET /metrics", %{conn: conn} do
    conn |> get("/api/example/junk")

    resp =
      conn
      |> get("/metrics")
      |> Map.get(:resp_body)

    assert resp =~ ~r/http_requests_total/
    assert resp =~ ~r/erlang_vm_memory_system_bytes_total/
  end
end
