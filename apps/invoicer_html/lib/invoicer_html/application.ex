defmodule InvoicerHtml.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: InvoicerHtml.PubSub},
      InvoicerHtml.Telemetry,
      InvoicerHtml.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    opts = [strategy: :one_for_one, name: InvoicerHtml.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    InvoicerHtml.Endpoint.config_change(changed, removed)
    :ok
  end
end
