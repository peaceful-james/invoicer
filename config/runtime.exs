import Config

app_name = :invoicer_pdf

env_var_name = fn atom_name ->
  atom_name
  |> to_string()
  |> String.upcase()
end

get_env_var_value = fn atom_name, default ->
  env_var_name.(atom_name)
  |> System.get_env(default)
end

get_env_var_value_without_default = fn atom_name ->
  get_env_var_value.(atom_name, nil)
end

get_env_var_value_with_non_prod_default = fn
  atom_name, non_prod_default ->
    default_value = if config_env() in [:prod], do: nil, else: non_prod_default
    value = get_env_var_value.(atom_name, default_value)

    if is_nil(value) and config_env() in [:prod],
      do:
        raise("""
        environment variable #{env_var_name.(atom_name)} is missing.
        """),
      else: value
end

get_necessary_env_var_value = fn atom_name ->
  value = get_env_var_value_without_default.(atom_name)

  if is_nil(value),
    do:
      raise("""
      environment variable #{env_var_name.(atom_name)} is missing.
      Your probably forgot to:
      ```
      cp .env.sample .env
      ```
      """),
    else: value
end

set_config = fn
  atom_name, non_prod_default ->
    value = get_env_var_value_with_non_prod_default.(atom_name, non_prod_default)
    config(app_name, atom_name, value)
end

set_non_default_config = fn atom_name ->
  value = get_necessary_env_var_value.(atom_name)
  config(app_name, atom_name, value)
end

cast_value = fn value, data_type ->
  case data_type do
    :atom ->
      String.to_existing_atom(value)

    :float ->
      {float, _remainder_of_binary} = Float.parse(value)
      float
  end
end

set_non_default_config_as = fn atom_name, data_type ->
  value = get_necessary_env_var_value.(atom_name)
  config(app_name, atom_name, cast_value.(value, data_type))
end

set_config.(:output_dir_name, "generated_pdfs")

[
  :company_name,
  :company_address_line_0,
  :company_address_line_1,
  :company_address_line_2,
  :company_address_line_3,
  :company_account_name,
  :company_bank_name,
  :company_iban,
  :company_bic
]
|> Enum.each(fn atom_name ->
  set_non_default_config.(atom_name)
end)

accepted_locales = Holidefs.locales() |> Map.keys()
accepted_currency_symbols = InvoicerPdf.Form |> Ecto.Enum.values(:currency_symbol)

InvoicerPdf.Clients.clients()
|> Enum.each(fn {client_key, %{locale: locale, currency_symbol: currency_symbol}} ->
  unless locale in accepted_locales do
    raise("""
    Locale \"#{locale}\" for client \"#{client_key}\" is invalid.

    Acceptable locale values are:
    #{inspect(accepted_locales, pretty: true)}
    """)
  end

  unless currency_symbol in accepted_currency_symbols do
    raise("""
    Locale \"#{currency_symbol}\" for client \"#{client_key}\" is invalid.

    Acceptable currency_symbol values are:
    #{inspect(accepted_currency_symbols, pretty: true)}
    """)
  end
end)
