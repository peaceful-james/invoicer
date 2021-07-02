import Config

app_name = :invoicer_pdf

get_env_var_value = fn
  atom_name, non_prod_default ->
    env_var_name = atom_name |> to_string() |> String.upcase()
    default_value = if config_env() in [:prod], do: nil, else: non_prod_default
    value = System.get_env(env_var_name, default_value)

    if is_nil(value) and config_env() in [:prod],
      do:
        raise("""
        environment variable #{env_var_name} is missing.
        """),
      else: value
end

get_env_var_value_without_default = fn atom_name ->
  env_var_name =
    atom_name
    |> to_string()
    |> String.upcase()

  value = System.get_env(env_var_name)

  if is_nil(value),
    do:
      raise("""
      Environment variable #{env_var_name} is missing.
      Your probably forgot to:
      ```
      cp .env.sample .env
      ```
      """),
    else: value
end

get_env_var_value_with_prod_default = fn
  atom_name, default_value ->
    env_var_name = atom_name |> to_string() |> String.upcase()
    System.get_env(env_var_name, default_value)
end

set_config = fn
  atom_name, non_prod_default ->
    value = get_env_var_value.(atom_name, non_prod_default)
    config(app_name, atom_name, value)
end

set_non_default_config = fn atom_name ->
  value = get_env_var_value_without_default.(atom_name)
  config(app_name, atom_name, value)
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
