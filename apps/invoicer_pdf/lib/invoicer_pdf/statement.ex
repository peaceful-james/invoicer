defmodule InvoicerPdf.Statement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "statement" do
    field(:number, :integer)
    field(:date, :date)
    field(:recipient_name, :string)
    field(:recipient_address, :string)
    field(:recipient_tax_id, :string)
    field(:services, {:array, :string})
    field(:charges, {:array, :decimal})
    field(:currency_symbol, Ecto.Enum, values: [:"€", :"$", :"£"])
  end

  def changeset(statement, attrs \\ %{}) do
    cast(statement, attrs, [
      :number,
      :date,
      :recipient_name,
      :recipient_address,
      :recipient_tax_id,
      :services,
      :charges,
      :currency_symbol
    ])
  end
end
