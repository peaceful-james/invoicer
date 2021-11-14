defmodule InvoicerPdf.ClientListSample do
  def client_list do
    %{
      pizza_people: %{
        recipient_name: "Super Pizza Palace",
        recipient_address: "Dough St, Berlin",
        rate_type: :day,
        rate_amount: Decimal.new("100.00"),
        locale: :de,
        currency_symbol: :"€"
      },
      clown_factory: %{
        recipient_name: "Clown Factory",
        recipient_address: "The Circus, New York",
        rate_type: :month,
        rate_amount: Decimal.new("4000.00"),
        locale: :us,
        currency_symbol: :"$"
      },
      dragon_grooming: %{
        recipient_name: "Dragon Grooming Inc.",
        recipient_address: "RPG Lane, Winterhold",
        rate_type: :semimonth,
        rate_amount: Decimal.new("2000.00"),
        locale: :ie,
        currency_symbol: :"€"
      }
    }
  end
end
