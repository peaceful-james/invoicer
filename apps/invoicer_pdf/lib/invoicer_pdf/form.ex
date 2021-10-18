defmodule InvoicerPdf.Form do
  use Ecto.Schema
  import Ecto.Changeset
  alias InvoicerPdf.{Clients, Holidays, OutputName, Rates, WorkingDays}

  @clients Clients.clients()
  @default_client_key Clients.default_client_key()

  @fields [
    :client_key,
    :output_name,
    :locale,
    :number,
    :recipient_name,
    :recipient_address,
    :date,
    :start_date,
    :end_date,
    :rate_type,
    :rate_amount,
    :days_off_count,
    :currency_symbol,
    :possible_holidays,
    :holidays
  ]

  schema "form" do
    field(:client_key, Ecto.Enum, values: Clients.client_keys())
    field(:output_name, :string)
    field(:locale, Ecto.Enum, values: Map.keys(Holidefs.locales()))
    field(:number, :integer)
    field(:recipient_name, :string)
    field(:recipient_address, :string)
    field(:date, :date)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:rate_type, Ecto.Enum, values: Rates.rate_types())
    field(:rate_amount, :string)
    field(:days_off_count, :integer)
    field(:currency_symbol, Ecto.Enum, values: [:"€", :"$", :"£"])
    field(:possible_holidays, {:array, :map})
    field(:holidays, {:array, :map})
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, @fields)
    |> then(fn changed_form ->
      case changed_form.changes do
        %{client_key: client_key} ->
          new(client_key) |> cast(%{}, @fields)

        _ ->
          changed_form
      end
    end)
    |> set_output_name()
    |> cast_holidays(attrs)
  end

  def new(client_key \\ @default_client_key) do
    client = Map.get(@clients, client_key)
    next_pdf_name_params = OutputName.next_pdf_name_params(client_key)

    Enum.reduce(
      @fields,
      %__MODULE__{},
      &Map.put(&2, &1, Map.get(next_pdf_name_params, &1, default(&1, client, client_key)))
    )
  end

  defp default(:client_key, _client, client_key), do: client_key
  defp default(key, client, _client_key), do: default(key, client)
  defp default(:client_key, _client), do: @default_client_key

  defp default(:output_name, client),
    do:
      OutputName.output_name(%{
        client_key: default(:client_key, client),
        number: default(:number, client),
        start_date: default(:start_date, client),
        end_date: default(:end_date, client)
      })

  defp default(:number, _client), do: 1
  defp default(:date, _client), do: Date.end_of_month(Date.utc_today())
  defp default(:start_date, _client), do: Date.beginning_of_month(Date.utc_today())
  defp default(:end_date, _client), do: Date.end_of_month(Date.utc_today())
  defp default(:days_off_count, _client), do: 0
  defp default(:possible_holidays, client), do: default(:holidays, client)

  defp default(:holidays, client),
    do:
      Holidays.holidays(
        default(:locale, client),
        default(:start_date, client),
        default(:end_date, client)
      )

  defp default(key, client), do: client[key]

  defp default(key), do: default(key, @clients[@default_client_key])

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
    rate_type = safe_get_field(changeset, :rate_type)
    rate_amount = safe_get_field(changeset, :rate_amount)
    days_off_count = safe_get_field(changeset, :days_off_count)
    currency_symbol = safe_get_field(changeset, :currency_symbol)
    holidays = safe_get_field(changeset, :holidays)
    ideal_days_count = WorkingDays.calculate_days_count(start_date, end_date, holidays)
    days_count = ideal_days_count - days_off_count

    charge =
      Rates.total(rate_type, rate_amount, %{
        days_count: days_count,
        start_date: start_date,
        end_date: end_date
      })

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
        "#{days_count} days worked between #{start_date} and #{end_date} (inclusive)#{maybe_days_off_string} at #{currency_symbol} #{rate_amount} per #{rate_type}, excluding weekends#{Holidays.holidays_string(holidays)}."
      ],
      charges: [to_string(charge)]
    }
  end

  defp set_output_name(changeset) do
    output_name =
      OutputName.output_name(%{
        client_key: get_field(changeset, :client_key),
        number: get_field(changeset, :number),
        start_date: get_field(changeset, :start_date),
        end_date: get_field(changeset, :end_date)
      })

    put_change(changeset, :output_name, output_name)
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
