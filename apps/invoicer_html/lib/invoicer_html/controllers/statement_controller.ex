defmodule InvoicerHtml.StatementController do
  use InvoicerHtml, :controller

  def index(conn, params) do
    assigns =
      params
      |> Map.take([
        "number",
        "currency_symbol",
        "date",
        "recipient_name",
        "recipient_address",
        "services",
        "charges"
      ])
      |> Enum.reduce(%{}, fn {key, val}, acc ->
        Map.put(acc, String.to_existing_atom(key), val)
      end)

    render(conn, "index.html", assigns)
  end

  def create(conn, params) do
    json(conn, InvoicerPdf.create(params))
  end
end
