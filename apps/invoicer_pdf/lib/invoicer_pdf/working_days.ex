defmodule InvoicerPdf.WorkingDays do
  @spec is_weekend?(%Date{}) :: boolean()
  def is_weekend?(date) do
    weekday_integer =
      date
      |> NaiveDateTime.new!(~T[01:00:00])
      |> Timex.weekday()

    weekday_integer in [6, 7]
  end

  @spec calculate_days_count(%Date{}, %Date{}, [%Holidefs.Holiday{}]) :: integer | nil
  def calculate_days_count(current_day, end_date, holidays \\ []) do
    holiday_dates = holidays |> Enum.map(& &1.date)
    days_count(current_day, end_date, holiday_dates, 0)
  end

  defp days_count(current_day, end_date, holiday_dates, days_count) do
    if Timex.after?(current_day, end_date) do
      0
    else
      next_day = Timex.shift(current_day, days: 1)

      new_days_count =
        if is_weekend?(current_day) or current_day in holiday_dates,
          do: days_count,
          else: days_count + 1

      if Timex.after?(next_day, end_date) do
        new_days_count
      else
        days_count(next_day, end_date, holiday_dates, new_days_count)
      end
    end
  end
end
