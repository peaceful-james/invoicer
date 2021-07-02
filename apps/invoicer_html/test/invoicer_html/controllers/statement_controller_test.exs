defmodule InvoicerHtml.StatementControllerTest do
  use InvoicerHtml.ConnCase

  @route "/statement"

  describe "POST /" do
    test "with good data", %{conn: conn} do
      output = InvoicerPdf.output_path("page_controller_test")

      conn =
        post(conn, @route, %{
          output: output,
          currency_symbol: "€",
          number: "42",
          date: "2021-05-18",
          services: ["hello", "yes"],
          charges: ["50.60", "49.40"]
        })

      assert json_response(conn, 200) == %{
               "result" => "ok",
               "output" => "/home/docker/invoicer/generated_pdfs/page_controller_test.pdf"
             }
    end
  end
end
