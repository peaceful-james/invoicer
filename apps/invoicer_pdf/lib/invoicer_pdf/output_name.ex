defmodule InvoicerPdf.OutputName do
  @output_dir Path.join([
                "/home/docker/invoicer",
                Application.get_env(:invoicer_pdf, :output_dir_name, "generated_pdfs")
              ])
  @separator "_"

  def output_dir, do: @output_dir

  def output_name(%{
        client_key: client_key,
        number: number,
        start_date: start_date,
        end_date: end_date
      }) do
    dir_name = to_string(client_key)

    file_name =
      [
        client_key,
        format_number(number),
        format_date(start_date),
        format_date(end_date)
      ]
      |> Enum.join(@separator)

    Path.join([dir_name, file_name])
  end

  def format_number(number) when is_number(number) do
    :io_lib.format("~6.8.0B", [number])
  end

  def format_number(_), do: "0"

  def format_date(date) do
    Date.to_iso8601(date)
  end

  def parse_date(date_string) do
    Date.from_iso8601(date_string)
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

  def last_pdf_name(client_key) do
    client_key
    |> traverse_generated_pdfs()
    |> Enum.sort()
    |> List.last()
  end

  def destructure_pdf_name(pdf_name) do
    pdf_name
    |> String.split(".")
    |> List.first()
    |> String.split(@separator)
  end

  def next_pdf_name_params(client_key) do
    client_key
    |> last_pdf_name()
    |> next_pdf_name_basic_params()
    |> then(&Map.put(&1, :output_name, output_name(Map.put(&1, :client_key, client_key))))
  end

  defp next_pdf_name_basic_params(nil) do
    start_date = Date.utc_today() |> Date.beginning_of_month()
    end_date = Date.utc_today() |> Date.end_of_month()
    %{number: 1, start_date: start_date, end_date: end_date}
  end

  defp next_pdf_name_basic_params(last_pdf_name) do
    with [_client_key, number, last_start_date_string, last_end_date_string] <-
           destructure_pdf_name(last_pdf_name),
         {:ok, last_start_date} <- parse_date(last_start_date_string),
         {:ok, last_end_date} <- parse_date(last_end_date_string) do
      last_days_diff = Timex.diff(last_end_date, last_start_date, :day)
      next_start_date = Timex.shift(last_end_date, days: 1)
      next_end_date = Timex.shift(last_end_date, days: 1 + last_days_diff)

      %{
        number: String.to_integer(number) + 1,
        start_date: next_start_date,
        end_date: next_end_date
      }
    else
      _ -> next_pdf_name_basic_params(nil)
    end
  end
end
