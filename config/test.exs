import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :invoicer_html, InvoicerHtml.Endpoint,
  http: [port: 4002],
  server: false
