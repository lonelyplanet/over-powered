defmodule DummyApp.Router do
  use DummyApp.Web, :router
  use OverPowered.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", DummyApp do
    pipe_through [:api, :auth, :instrumentation]
    get "/example/:id", ExampleController, :index
  end

  health_check config: :dummy_app
end
