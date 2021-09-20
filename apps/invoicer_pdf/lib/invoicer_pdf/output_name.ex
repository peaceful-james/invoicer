defmodule InvoicerPdf.OutputName do
  @output_dir Path.join([
                "/home/docker/invoicer",
                Application.get_env(:invoicer_pdf, :output_dir_name, "generated_pdfs")
              ])

  def output_dir, do: @output_dir

  def output_name(
        %{
          client_key: client_key,
          number: number,
          date: date
        },
        time_unit \\ :monthly
      ) do
    Path.join([
      to_string(client_key),
      "#{client_key}-#{:io_lib.format("~6.8.0B", [number])}-#{format(date, time_unit)}"
    ])
  end

  def format(date, :monthly) do
    date |> Calendar.strftime("%B-%Y") |> String.downcase()
  end

  @doc """
  Returns list of filenames of generated pdfs for the given client_key.
  If no dir exists for the given client key, a dir is created.
  """
  def traverse_generated_pdfs(client_key) do
    dir =
      client_key
      |> to_string()
      |> Path.absname(@output_dir)

    unless File.exists?(dir) do
      File.mkdir!(dir)
    end

    File.ls!(dir)
  end

  def next_pdf_name_params(client_key) do
    case client_key
         |> traverse_generated_pdfs()
         |> Enum.sort()
         |> List.last() do
      nil ->
        date = Date.utc_today() |> Date.end_of_month()
        %{number: 1, date: date}

      last_pdf_name ->
        [_client_key, number, month, year] =
          last_pdf_name
          |> String.split(".")
          |> List.first()
          |> String.split("-")

        last_pdf_date = Date.new!(String.to_integer(year), Timex.month_to_num(month), 1)
        date = last_pdf_date |> Timex.shift(months: 1) |> Date.end_of_month()
        %{number: String.to_integer(number) + 1, date: date}
    end
    |> then(&Map.put(&1, :start_date, &1[:date] |> Date.beginning_of_month()))
    |> then(&Map.put(&1, :end_date, &1[:date]))
    |> then(&Map.put(&1, :output_name, output_name(Map.put(&1, :client_key, client_key))))
  end
end
