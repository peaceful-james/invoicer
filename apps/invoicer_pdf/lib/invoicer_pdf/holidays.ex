defmodule InvoicerPdf.Holidays do
  alias InvoicerPdf.DateUtils

  def locales_for_select() do
    Holidefs.locales()
    |> Enum.map(fn {key, val} -> {val, key} end)
    |> Enum.sort()
  end

  def holidays(locale, start_date, end_date) do
    with {:ok, start_date} <- DateUtils.to_date(start_date),
         {:ok, end_date} <- DateUtils.to_date(end_date),
         {:ok, holidays} <- Holidefs.between(locale, start_date, end_date) do
      holidays
    else
      _ -> []
    end
  end

  def holidays_string([]), do: ""

  def holidays_string(holidays) do
    holidays_string =
      holidays
      |> Enum.map(fn %{name: name, date: date} -> "#{date} (#{name})" end)
      |> Enum.join(", ")

    " and public holidays: #{holidays_string}"
  end
end
