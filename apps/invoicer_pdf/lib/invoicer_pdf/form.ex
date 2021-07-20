defmodule InvoicerPdf.Form do
  use Ecto.Schema
  import Ecto.Changeset
  alias InvoicerPdf.{Holidays, WorkingDays}

  @fields [
    :output_name,
    :locale,
    :number,
    :recipient_name,
    :recipient_address,
    :date,
    :start_date,
    :end_date,
    :days_rate,
    :days_off_count,
    :currency_symbol,
    :possible_holidays,
    :holidays
  ]

  schema "form" do
    field(:output_name, :string)
    field(:locale, Ecto.Enum, values: Map.keys(Holidefs.locales()))
    field(:number, :integer)
    field(:recipient_name, :string)
    field(:recipient_address, :string)
    field(:date, :date)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:days_rate, :float)
    field(:days_off_count, :integer)
    field(:currency_symbol, Ecto.Enum, values: [:"€", :"$", :"£"])
    field(:possible_holidays, {:array, :map})
    field(:holidays, {:array, :map})
  end

  def changeset(form, attrs \\ %{}) do
    cast(form, attrs, @fields)
    |> cast_holidays(attrs)
  end

  def new, do: Enum.reduce(@fields, %__MODULE__{}, &Map.put(&2, &1, default(&1)))

  defp default(:output_name), do: "test"
  defp default(:locale), do: Application.get_env(:invoicer_pdf, :default_locale)
  defp default(:number), do: 1
  defp default(:recipient_name), do: Application.get_env(:invoicer_pdf, :default_recipient_name)

  defp default(:recipient_address),
    do: Application.get_env(:invoicer_pdf, :default_recipient_address)

  defp default(:date), do: Timex.shift(Date.utc_today(), days: 0)
  defp default(:start_date), do: Timex.shift(Date.utc_today(), days: -30)
  defp default(:end_date), do: Timex.shift(Date.utc_today(), days: 0)
  defp default(:days_rate), do: Application.get_env(:invoicer_pdf, :default_days_rate)
  defp default(:days_off_count), do: 0
  defp default(:currency_symbol), do: Application.get_env(:invoicer_pdf, :default_currency_symbol)
  defp default(:possible_holidays), do: default(:holidays)

  defp default(:holidays),
    do: Holidays.holidays(default(:locale), default(:start_date), default(:end_date))

  defp safe_get_attr(changeset, attrs, field_name) do
    Map.get(attrs, to_string(field_name), safe_get_field(changeset, field_name))
  end

  defp safe_get_field(changeset, field_name) do
    safe_get_field(changeset, field_name, default(field_name))
  end

  defp safe_get_field(changeset, field_name, default) do
    get_field(changeset, field_name, default) || default
  end

  @spec to_statement_params(%Ecto.Changeset{}) :: map()
  def to_statement_params(changeset) do
    output_name = safe_get_field(changeset, :output_name)
    number = safe_get_field(changeset, :number)
    recipient_name = safe_get_field(changeset, :recipient_name)
    recipient_address = safe_get_field(changeset, :recipient_address)
    date = safe_get_field(changeset, :date)
    start_date = safe_get_field(changeset, :start_date)
    end_date = safe_get_field(changeset, :end_date)
    days_rate = safe_get_field(changeset, :days_rate)
    days_off_count = safe_get_field(changeset, :days_off_count)
    currency_symbol = safe_get_field(changeset, :currency_symbol)
    holidays = safe_get_field(changeset, :holidays)

    ideal_days_count = WorkingDays.calculate_days_count(start_date, end_date, holidays)
    days_count = ideal_days_count - days_off_count
    days_rate_string = days_rate |> :erlang.float_to_binary(decimals: 2)

    maybe_days_off_string =
      cond do
        days_off_count == 1 ->
          " with #{days_off_count} day off"

        days_off_count > 0 ->
          " with #{days_off_count} days off"

        true ->
          ""
      end

    %{
      date: "#{date}",
      output_name: output_name,
      number: number,
      recipient_name: recipient_name,
      recipient_address: recipient_address,
      currency_symbol: currency_symbol,
      services: [
        "#{days_count} days worked between #{start_date} and #{end_date} (inclusive)#{maybe_days_off_string} at #{currency_symbol} #{days_rate_string} per day, excluding weekends#{Holidays.holidays_string(holidays)}."
      ],
      charges: [to_string(days_count * days_rate)]
    }
  end

  defp cast_holidays(changeset, attrs) do
    locale = safe_get_attr(changeset, attrs, :locale)
    start_date = safe_get_attr(changeset, attrs, :start_date)
    end_date = safe_get_attr(changeset, attrs, :end_date)

    selected_holidays =
      attrs
      |> Enum.filter(fn
        {"holiday-" <> _, "true"} -> true
        _ -> false
      end)
      |> Enum.map(fn {"holiday-" <> key_suffix, _} -> Date.from_iso8601!(key_suffix) end)

    possible_holidays = Holidays.holidays(locale, start_date, end_date)
    holidays = Enum.filter(possible_holidays, fn %{date: date} -> date in selected_holidays end)

    changeset
    |> put_change(:holidays, holidays)
    |> put_change(:possible_holidays, possible_holidays)
  end
end