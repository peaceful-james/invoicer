defmodule InvoicerHtml.Router do
  use InvoicerHtml, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {InvoicerHtml.LayoutView, :root}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", InvoicerHtml do
    pipe_through :browser

    live "/", Home
    get "/statement", StatementController, :index
    post "/statement", StatementController, :create
  end
end
