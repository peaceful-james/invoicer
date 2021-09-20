defmodule InvoicerPdf.ClientListSample do
  def client_list do
    %{
      pizza_people: %{
        recipient_name: "Super Pizza Palace",
        recipient_address: "Dough St, Berlin",
        days_rate: 100.00,
        locale: :de,
        currency_symbol: :"€"
      },
      clown_factory: %{
        recipient_name: "Clown Factory",
        recipient_address: "The Circus, New York",
        days_rate: 130.00,
        locale: :us,
        currency_symbol: :"$"
      }
    }
  end
end
