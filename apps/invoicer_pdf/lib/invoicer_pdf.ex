defmodule InvoicerPdf do
  @moduledoc """
  Documentation for `InvoicerPdf`.
  """

  alias InvoicerPdf.OutputName

  @default_opts [
    print_to_pdf: %{
      marginTop: 0.0,
      marginLeft: 0.0,
      marginRight: 0.0,
      marginBottom: 0.0
    }
  ]

  def print_to_pdf(input, opts \\ []) do
    ChromicPDF.print_to_pdf(input, Keyword.merge(opts, @default_opts))
  end

  def statement_url(params) when is_map(params) do
    number = params |> generic_map_get(:number)
    date = params |> generic_map_get(:date, default_date())
    recipient_name = params |> generic_map_get(:recipient_name)
    recipient_address = params |> generic_map_get(:recipient_address)
    services = params |> generic_map_get(:services, [])
    charges = params |> generic_map_get(:charges, [])
    currency_symbol = params |> generic_map_get(:currency_symbol)

    base_url = "http://localhost:4000/statement?"
    number_param = "number=#{number}"
    date_param = "date=#{date}"
    recipient_name_param = "recipient_name=#{recipient_name}"
    recipient_address_param = "recipient_address=#{recipient_address}"
    currency_symbol_param = "currency_symbol=#{currency_symbol}"
    services_param = services |> Enum.map(&"services[]=#{&1}") |> Enum.join("&")
    charges_param = charges |> Enum.map(&"charges[]=#{&1}") |> Enum.join("&")

    (base_url <>
       Enum.join(
         [
           number_param,
           currency_symbol_param,
           date_param,
           recipient_name_param,
           recipient_address_param,
           services_param,
           charges_param
         ],
         "&"
       ))
    |> URI.encode()
  end

  def create(params) when is_map(params) do
    output_name = params |> generic_map_get(:output_name, "output")
    output = params |> generic_map_get(:output, output_path(output_name))
    url = statement_url(params)
    result = print_to_pdf({:url, url}, output: output)
    %{result: result, output: output}
  end

  @doc """
  Returns the full path for a generated pdf using the given name
  """
  def output_path(name) do
    Path.join([OutputName.output_dir(), "#{name}.pdf"])
  end

  defp generic_map_get(map, atom_key, default \\ nil) do
    map
    |> Map.take([atom_key, to_string(atom_key)])
    |> Map.values()
    |> List.first() || default
  end

  defp default_date() do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.to_date()
    |> to_string()
  end
end
