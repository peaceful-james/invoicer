defmodule InvoicerPdf.Rates do
  @moduledoc """
  Functions associated rates.
  """
  alias InvoicerPdf.WorkingDays
  @rate_types [:day, :month]

  @doc """
  A list of all the rate types
  """
  def rate_types, do: @rate_types

  @spec total(:day | :month, Decimal.t(), %{
          days_count: integer(),
          start_date: Date.t(),
          end_date: Date.t()
        }) :: Decimal.t()

  def total(:day, rate_amount, %{days_count: days_count}) do
    Decimal.mult(rate_amount, days_count)
  end

  def total(:month, rate_amount, %{start_date: start_date, end_date: end_date}) do
    months(start_date, end_date)
    |> Decimal.mult(rate_amount)
  end

  @spec months(Date.t(), Date.t(), Decimal.t()) :: Decimal.t()
  def months(date, end_date, days \\ Decimal.new(0)) do
    days_in_month = Date.days_in_month(date)

    if date.month == end_date.month do
      (1 + end_date.day - date.day)
      |> Decimal.div(days_in_month)
      |> Decimal.add(days)
    else
      new_date =
        date
        |> Timex.shift(months: 1)
        |> Date.beginning_of_month()

      new_days =
        (1 + days_in_month - date.day)
        |> Decimal.div(days_in_month)
        |> Decimal.add(days)

      months(new_date, end_date, new_days)
    end
  end
end
