defmodule InvoicerPdf.Rates do
  @moduledoc """
  Functions associated rates.
  """
  @rate_types [:day, :month, :semimonth]
  @type rate :: unquote(Enum.reduce(@rate_types, &{:|, [], [&1, &2]}))

  @doc """
  A list of all the rate types
  """
  def rate_types, do: @rate_types

  @doc """
  Calculates the total amount to be charged depending
  on the rate_type, rate_amount and days worked.
  The logic for the difference rate_types is as follows:

  - `:day` - the rate_amount is multiplied by the "days count",
  which is calculated using the WorkingDays module

  - `:month` - effectively, the given start_date and end_date
  are diffed to produce a float which is multiplied by the monthly
  rate. The result is usually very precise, and varies from invoice
  to invoice if invoicing twice a month.
  For example, given a start_date of 25th September and an
  end_date of 10th October
  let days_in_september = x
  let days_in_october = y
  then the total would be:
  (((x - 25) / x) + (10 / y)) * monthly_rate

  - `:semimonth` - the "approximate fornight diff" between
  start_date and end_date is calculated as an integer, which is
  then multiplied by the semimonthly rate.
  This is useful for clients who want semimonthly invoices of
  consistent amounts. For example, 10, 11, 12...20 days will all
  result in the same total!
  """
  @spec total(:day | :month | :semimonth, Decimal.t(), %{
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

  def total(:semimonth, rate_amount, %{start_date: start_date, end_date: end_date}) do
    approximate_number_of_fortnights =
      end_date
      |> Date.diff(start_date)
      |> Kernel./(14.0)
      |> round()

    Decimal.mult(rate_amount, approximate_number_of_fortnights)
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
