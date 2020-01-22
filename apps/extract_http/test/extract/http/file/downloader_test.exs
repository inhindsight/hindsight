defmodule Extract.Http.File.DownloaderTest do
  use ExUnit.Case
  use Placebo

  alias Plug.Conn
  alias Extract.Http.File.Downloader

  setup do
    on_exit(fn -> File.rm("test.output") end)
    [bypass: Bypass.open()]
  end

  test "downloads the file correctly", %{bypass: bypass} do
    Bypass.stub(bypass, "GET", "/file/to/download", fn conn ->
      conn = Conn.send_chunked(conn, 200)

      Enum.reduce_while(~w|each chunk as a word|, conn, fn chunk, acc ->
        case Conn.chunk(acc, chunk) do
          {:ok, conn} -> {:cont, conn}
          {:error, :closed} -> {:halt, conn}
        end
      end)
    end)

    {:ok, response} =
      Downloader.download("http://localhost:#{bypass.port}/file/to/download", to: "test.output")

    assert "eachchunkasaword" == File.read!("test.output")
    assert response.status == 200
    assert response.destination == "test.output"
    assert response.done == true
    assert response.url == "http://localhost:#{bypass.port}/file/to/download"
  end

  test "downloads file correctly with http post", %{bypass: bypass} do
    Bypass.stub(bypass, "POST", "/file/to/download", fn conn ->
      {:ok, body, conn} = Conn.read_body(conn)
      assert body == "This is the body!"
      conn = Conn.send_chunked(conn, 200)

      Enum.reduce_while(~w|each chunk as a word|, conn, fn chunk, acc ->
        case Conn.chunk(acc, chunk) do
          {:ok, conn} -> {:cont, conn}
          {:error, :closed} -> {:halt, conn}
        end
      end)
    end)

    {:ok, response} =
      Downloader.download("http://localhost:#{bypass.port}/file/to/download",
        to: "test.output",
        method: "POST",
        body: "This is the body!"
      )

    assert "eachchunkasaword" == File.read!("test.output")
    assert response.status == 200
    assert response.destination == "test.output"
    assert response.done == true
    assert response.url == "http://localhost:#{bypass.port}/file/to/download"
  end

  test "raises an error when unable to connect", %{bypass: bypass} do
    Bypass.down(bypass)

    assert {:error, %Mint.TransportError{}} =
             Downloader.download("http://localhost:#{bypass.port}/file/to/download.csv",
               to: "fake.file"
             )
  end

  @tag capture_log: true
  test "raises an error when request returns a non 200 status code", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      Conn.send_resp(conn, 404, "Not Found")
    end)

    {:error, reason} =
      Downloader.download("http://localhost:#{bypass.port}/file/to/download", to: "test.output")

    assert reason ==
             Downloader.InvalidStatusError.exception(
               message: "Invalid status code: 404",
               status: 404
             )
  end

  test "raises an error when request is made" do
    allow(Mint.HTTP.connect(any(), any(), any(), any()), return: {:ok, :connection})

    allow(Mint.HTTP.request(:connection, any(), any(), any(), any()),
      return:
        {:error, :connection, Mint.TransportError.exception(reason: "things have gone wrong")}
    )

    allow(Mint.HTTP.close(any()), return: :ok)

    assert {:error, %Mint.TransportError{}} =
             Downloader.download("http://some.url", to: "test.output")

    assert_called(Mint.HTTP.close(:connection), once())
  end

  test "raises an error when processing a stream message", %{bypass: bypass} do
    allow(Mint.HTTP.connect(any(), any(), any(), any()), return: {:ok, :connection})

    allow(Mint.HTTP.request(:connection, any(), any(), any(), any()),
      return: {:ok, :connection, :ref}
    )

    allow(Mint.HTTP.stream(any(), any()),
      return: {:error, :connection, %Mint.TransportError{reason: :closed}, []},
      meck_options: [:passthrough]
    )

    allow(Mint.HTTP.close(any()), return: :ok)

    Process.send(self(), :msg, [])

    path = "/some.url"
    url = "http://localhost:#{bypass.port}#{path}"

    assert {:error, %Mint.TransportError{}} = Downloader.download(url, to: "test.output")
  end

  test "handles 301 redirects", %{bypass: bypass} do
    Bypass.stub(bypass, "GET", "/some/file.csv", fn conn ->
      conn
      |> Conn.put_resp_header("location", "http://localhost:#{bypass.port}/some/other/file.csv")
      |> Conn.send_resp(301, "")
    end)

    Bypass.stub(bypass, "GET", "/some/other/file.csv", fn conn ->
      Conn.send_resp(conn, 200, "howdy")
    end)

    Downloader.download("http://localhost:#{bypass.port}/some/file.csv", to: "test.output")

    assert "howdy" == File.read!("test.output")
  end

  test "handles 302 redirects", %{bypass: bypass} do
    Bypass.stub(bypass, "GET", "/some/file.csv", fn conn ->
      conn
      |> Conn.put_resp_header("location", "http://localhost:#{bypass.port}/some/other/file.csv")
      |> Conn.send_resp(302, "")
    end)

    Bypass.stub(bypass, "GET", "/some/other/file.csv", fn conn ->
      Conn.send_resp(conn, 200, "howdy")
    end)

    Downloader.download("http://localhost:#{bypass.port}/some/file.csv", to: "test.output")

    assert "howdy" == File.read!("test.output")
  end

  test "passes connect timeout to tcp library", %{bypass: bypass} do
    allow(Mint.HTTP.connect(any(), any(), any(), any()),
      exec: fn a, b, c, d ->
        :meck.passthrough([a, b, c, d])
      end
    )

    path = "/some.url"
    url = "http://localhost:#{bypass.port}#{path}"

    Bypass.stub(bypass, "GET", path, fn conn ->
      Plug.Conn.resp(conn, 200, "data")
    end)

    Downloader.download(url,
      to: "test.output",
      connect_timeout: 60_000
    )

    assert_called(
      Mint.HTTP.connect(:http, "localhost", bypass.port, transport_opts: [timeout: 60_000]),
      once()
    )
  end

  test "only waits idle_timeout to receive message from process queue" do
    allow(Mint.HTTP.connect(any(), any(), any(), any()), return: {:ok, :connection})

    allow(Mint.HTTP.request(:connection, any(), any(), any(), any()),
      return: {:ok, :connection, :ref}
    )

    allow(Mint.HTTP.close(any()), return: :ok)

    expected_error =
      Downloader.IdleTimeoutError.exception(
        timeout: 50,
        message:
          "Idle timeout was reached while attempting to download http://localhost/some.file"
      )

    assert {:error, expected_error} ==
             Downloader.download("http://localhost/some.file", to: "test.output", idle_timeout: 50)
  end

  test "evaluate paramaters in headers", %{bypass: bypass} do
    allow(Mint.HTTP.request(:connection, any(), any(), any(), any()),
      exec: fn a, b, c, d ->
        :meck.passthrough([a, b, c, d])
      end
    )

    path = "/some.url"
    url = "http://localhost:#{bypass.port}#{path}"

    Bypass.stub(bypass, "GET", path, fn conn ->
      Plug.Conn.resp(conn, 200, "data")
    end)

    headers = %{
      "testKey" => "<%= Date.to_iso8601(~D[1970-01-02], :basic) %>",
      :testB => "valB"
    }

    evaluated_headers = [{"testB", "valB"}, {"testKey", "19700102"}]

    {:ok, _} = Downloader.download(url, to: "test.output", headers: headers)

    assert_called(Mint.HTTP.request(any(), any(), any(), evaluated_headers, any()), once())
  end

  test "protocol is used for connection", %{bypass: bypass} do
    allow(Mint.HTTP.connect(any(), any(), any(), any()),
      exec: fn a, b, c, d ->
        :meck.passthrough([a, b, c, d])
      end
    )

    path = "/some.url"
    url = "http://localhost:#{bypass.port}#{path}"

    Bypass.stub(bypass, "GET", path, fn conn ->
      Plug.Conn.resp(conn, 200, "data")
    end)

    {:ok, _} = Downloader.download(url, to: "test.output", protocol: ["http1"])

    uri = URI.parse(url)
    scheme = String.to_atom(uri.scheme)

    assert_called(
      Mint.HTTP.connect(scheme, uri.host, uri.port,
        transport_opts: [timeout: 30_000],
        protocols: [:http1]
      ),
      once()
    )
  end

  test "nil protocol is not used", %{bypass: bypass} do
    path = "/some.url"
    url = "http://localhost:#{bypass.port}#{path}"

    Bypass.stub(bypass, "GET", path, fn conn ->
      Plug.Conn.resp(conn, 200, "data")
    end)

    allow(Mint.HTTP.connect(any(), any(), any(), any()),
      exec: fn a, b, c, d ->
        :meck.passthrough([a, b, c, d])
      end
    )

    {:ok, _} = Downloader.download(url, to: "test.output")

    uri = URI.parse(url)
    scheme = String.to_atom(uri.scheme)

    assert_called(
      Mint.HTTP.connect(scheme, uri.host, uri.port, transport_opts: [timeout: 30_000]),
      once()
    )
  end
end
