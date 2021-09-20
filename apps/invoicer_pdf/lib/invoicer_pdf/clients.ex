defmodule InvoicerPdf.Clients do
  @clients InvoicerPdf.ClientList.client_list()
  @client_keys Map.keys(@clients)
  @default_client_key List.first(@client_keys)
  @default_client Map.get(@clients, @default_client_key)

  @doc """
  A map of all the clients' details
  """
  def clients, do: @clients

  @doc """
  A list of all the client keys
  """
  def client_keys, do: @client_keys

  @doc """
  The default client to use in a new form
  """
  def default_client, do: @default_client

  @doc """
  The default client key to use in a new form
  """
  def default_client_key, do: @default_client_key
end
