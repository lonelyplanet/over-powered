defmodule DummyApp.ExampleController do
  use DummyApp.Web, :controller

  def index(conn, _params) do
    conn
    |> put_status(200)
    |> render("show.json")
  end
end
