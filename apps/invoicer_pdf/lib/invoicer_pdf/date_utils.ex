defmodule InvoicerPdf.DateUtils do
  def to_date(%{"year" => year, "month" => month, "day" => day}) do
    year = String.to_integer(year)
    month = String.to_integer(month)
    day = String.to_integer(day)
    Date.new(year, month, day)
  end

  def to_date(%Date{} = date), do: {:ok, date}
end
