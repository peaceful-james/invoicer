defmodule InvoicerHtml.Home do
  use InvoicerHtml, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> put_assigns()
     |> assign(:print_result, "fill out the form and click the big blue button")}
  end

  @impl true
  def handle_event("change", %{"form" => form_params}, socket) do
    {:noreply, put_assigns(socket, form_params)}
  end

  @impl true
  def handle_event(
        "submit",
        %{"form" => %{"output_name" => output_name}},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    output = InvoicerPdf.output_path(output_name)
    :ok = InvoicerPdf.print_to_pdf({:url, socket.assigns.statement_url}, output: output)
    real_output = String.replace(output, "/home/docker/invoicer/", "")

    socket =
      socket
      |> assign(:print_result, "saved to #{real_output}")
      |> assign(
        :changeset,
        changeset
        |> Ecto.Changeset.get_field(:client_key)
        |> InvoicerPdf.Form.new()
        |> InvoicerPdf.Form.changeset()
      )
      |> assign_statement_params()
      |> assign_statement_url()

    {:noreply, socket}
  end

  defp put_assigns(socket, params \\ %{}) do
    socket
    |> assign_changeset(params)
    |> assign_statement_params()
    |> assign_statement_url()
  end

  defp assign_changeset(socket, params) do
    changeset =
      socket.assigns
      |> Map.get(:changeset, InvoicerPdf.Form.new())
      |> InvoicerPdf.Form.changeset(params)

    assign(socket, :changeset, changeset)
  end

  defp assign_statement_params(socket) do
    statement_params = InvoicerPdf.Form.to_statement_params(socket.assigns.changeset)
    assign(socket, :statement_params, statement_params)
  end

  defp assign_statement_url(socket) do
    statement_url = InvoicerPdf.statement_url(socket.assigns.statement_params)
    assign(socket, :statement_url, statement_url)
  end
end
