defmodule WorkingDaysAndHolidaysTest do
  use ExUnit.Case
  alias InvoicerPdf.{Holidays, WorkingDays}

  describe "calculate_days_count/4" do
    test "correctly calculates number of working days in a timespan" do
      [
        %{
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-01-31],
          expected:
            {20,
             [
               %Holidefs.Holiday{
                 date: ~D[2021-01-01],
                 informal?: false,
                 name: "New Year's Day",
                 observed_date: ~D[2021-01-01],
                 raw_date: ~D[2021-01-01]
               }
             ]}
        },
        %{
          start_date: ~D[2021-05-01],
          end_date: ~D[2021-05-31],
          expected:
            {20,
             [
               %Holidefs.Holiday{
                 date: ~D[2021-05-03],
                 informal?: false,
                 name: "May Day",
                 observed_date: ~D[2021-05-03],
                 raw_date: ~D[2021-05-03]
               }
             ]}
        },
        %{
          start_date: ~D[2021-12-01],
          end_date: ~D[2021-12-31],
          expected:
            {23,
             [
               %Holidefs.Holiday{
                 date: ~D[2021-12-25],
                 informal?: false,
                 name: "Christmas Day",
                 observed_date: ~D[2021-12-27],
                 raw_date: ~D[2021-12-25]
               },
               %Holidefs.Holiday{
                 date: ~D[2021-12-26],
                 informal?: false,
                 name: "St. Stephen's Day",
                 observed_date: ~D[2021-12-28],
                 raw_date: ~D[2021-12-26]
               }
             ]}
        },
        %{
          start_date: ~D[2023-12-01],
          end_date: ~D[2023-12-31],
          expected:
            {19,
             [
               %Holidefs.Holiday{
                 date: ~D[2023-12-25],
                 informal?: false,
                 name: "Christmas Day",
                 observed_date: ~D[2023-12-25],
                 raw_date: ~D[2023-12-25]
               },
               %Holidefs.Holiday{
                 date: ~D[2023-12-26],
                 informal?: false,
                 name: "St. Stephen's Day",
                 observed_date: ~D[2023-12-26],
                 raw_date: ~D[2023-12-26]
               }
             ]}
        }
      ]
      |> Enum.each(fn %{start_date: start_date, end_date: end_date, expected: expected} ->
        holidays = Holidays.holidays(:ie, start_date, end_date)
        working_days = WorkingDays.calculate_days_count(start_date, end_date, holidays)
        result = {working_days, holidays}

        assert result == expected,
               """
               Wrong result for start_date #{start_date}, end_date #{end_date}.
               Was #{inspect(result, pretty: true)}, expected #{inspect(expected, pretty: true)}.
               """
      end)
    end
  end
end
