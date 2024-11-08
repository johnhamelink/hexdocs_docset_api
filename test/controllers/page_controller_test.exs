defmodule DocsetApi.FeedControllerTest do
  use DocsetApi.ConnCase
  import ExUnit.CaptureLog

  test "GET /feeds/ecto", %{conn: conn} do
    # TODO: Mock Builder so that we don't actually download any
    # hexdocs.
    conn = get(conn, "/feeds/ecto")
    assert response(conn, 200) =~ "/docsets/ecto-"
  end

  test "GET /feeds/sdfjnfdkjn", %{conn: conn} do
    # TODO: Mock Builder so that we don't actually download any
    # hexdocs.
    capture_log(fn ->
      resp = get(conn, "/feeds/sdfjnfdkjn")
      assert resp.status == 404
      assert resp.resp_body =~ "Docset not found"
    end)
  end
end
