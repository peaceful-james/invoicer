# Invoicer

### First-time setup

```shell
asdf install
mix deps.get
mix deps.compile
mix compile
cp .env.sample .env
cp apps/invoicer_pdf/lib/invoicer_pdf/client_list.sample.ex apps/invoicer_pdf/lib/invoicer_pdf/client_list.ex
```

Edit the first line of `apps/invoicer_pdf/lib/invoicer_pdf/client_list.ex` to this:

```
defmodule InvoicerPdf.ClientList do
```

Edit `.env` to contain your personal/company details.

Edit `apps/invoicer_pdf/lib/invoicer_pdf/client_list.ex` to contain your client(s) details.


Then finish setting up:

```
docker-compose build
docker network create my-network --subnet 172.24.24.0/24 # to avoid openvpn route collision https://stackoverflow.com/questions/45692255/how-make-openvpn-work-with-docker
```

You can also provide your own custom logo:

```shell
cp ~/my-company-logo.png apps/invoicer_html/assets/static/images/logo.png
```

### Quickstart

Run the app:

```shell
docker-compose up
```

Now visit `http://localhost:4000`, fill in the form and press the button.

The default form values should save a file in `generated_pdfs/`.

### Disclaimer

The styling on the generated PDF might be different to the styling in the browser.
This all depends on what browser you're using.

### More Details Than You Need

The form runs a function that actually hits another endpoint (called `statement`) in the `:invoicer_html` web app.

Here is an example URL of this "pre-pdf html" endpoint:

```
http://localhost:4000/statement?number=1&currency_symbol=$&date=2021-05-10&recipient_name=Client%20Name&recipient_address=Client%20Address&services[]=21%20days%20worked%20between%202021-12-01%20and%202021-12-31%20(inclusive)%20with%202%20days%20off%20at%20$%20100.00%20per%20day,%20excluding%20weekends%20and%20public%20holidays%20(2021-12-25).&charges[]=7035.0
```

You can attach a new `iex` shell to the running server using this:

```shell
docker-compose exec invoicer iex --sname invoicer-dev --remsh invoicer@$(docker ps --filter "name=invoicer_invoicer" -q)
```

Note that the `sname` in this command can be anything you like (except `invoicer`, which is already being used by the actual app node).

In the iex shell, make your pdfs like this (they appear on host `generated_pdfs` folder this way):

```elixir
InvoicerPdf.create(%{number: 1, date: "2021-05-17", services: ["something", "job"], charges: [45.23, 76.77]})
```

or (this is my favourite)

```elixir
%{number: 1, start_date: ~D[2021-12-01], end_date: ~D[2021-12-31], rate_amount: 100.00, rate_type: :day} |> InvoicerPdf.create()
```

or

```elixir
%{number: 1, start_date: ~D[2021-12-01], end_date: ~D[2021-12-31], days_off_count: 2, rate_amount: 100.00, rate_type: :month, currency_symbol: "$"} |> InvoicerPdf.create()
```

This function:

```
InvoicerPdf.create()
```

actually hits the `:invoicer_html` endpoint to get the invoice HTML which is then converted into a PDF using ChromicPdf.
