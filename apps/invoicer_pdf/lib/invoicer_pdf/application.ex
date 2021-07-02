defmodule InvoicerPdf.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {ChromicPDF, discard_stderr: false}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    opts = [strategy: :one_for_one, name: InvoicerPdf.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
