import
  asyncdispatch,
  asynchttpserver,
  asyncstreams,
  json,
  httpcore,
  httpclient,
  unittest,
  uri,
  streams
import http_har

proc getRequest(): Request =
  result = Request()
  result.body = "'hello world'"
  result.reqMethod = HttpPost
  result.url = parseUri("https://example.com?foo=bar&baz=123")
  result.protocol = (orig: "HTTP/1.1", major: 1, minor: 1)
  result.headers = newHttpHeaders()
  result.headers.add("content-type", "application/json")

proc getResponse(): Response =
  result = Response()
  result.version = "HTTP/1.1"
  result.status = "200"
  result.headers = newHttpHeaders()
  result.headers.add("content-type", "application/json")
  result.bodyStream = newStringStream("'Hello world'")

proc getAsyncResponse(): AsyncResponse =
  result = AsyncResponse()
  result.version = "HTTP/1.1"
  result.status = "200"
  result.headers = newHttpHeaders()
  result.headers.add("content-type", "application/json")
  result.bodyStream = newFutureStream[string]("'Hello world'")

suite "common":

  test "start":
    let s = start()
    check:
      s["log"]["version"].getStr() == "1.2"

  test "convertHeaders":
    let headers = newHttpHeaders(@[("foo", "bar"), ("baz", "123")])
    let converted = convertHeaders(headers)
    check:
      converted[0]["name"].getStr() == "foo"
      converted[0]["value"].getStr() == "bar"
      converted[1]["name"].getStr() == "baz"
      converted[1]["value"].getStr() == "123"

  test "convertCookies":
    let headers = newHttpHeaders(@[("something", "else"), ("Cookie", "foo=bar; baz=123")])
    let converted = convertCookies(headers)
    check:
      converted[0]["name"].getStr() == "foo"
      converted[0]["value"].getStr() == "bar"
      converted[1]["name"].getStr() == "baz"
      converted[1]["value"].getStr() == "123"

  test "convertQueryString":
    let u = parseUri("http://localhost?foo=bar&baz=123")
    let converted = convertQueryString(u)
    check:
      converted[0]["name"].getStr() == "foo"
      converted[0]["value"].getStr() == "bar"
      converted[1]["name"].getStr() == "baz"
      converted[1]["value"].getStr() == "123"

suite "sync":

  test "convert - request":
    let converted = convert(getRequest())
    let expected = parseJson("""{"bodySize":13,"method":"POST","url":"https://example.com?foo=bar&baz=123","httpVersion":"HTTP/1.1","headers":[{"name":"content-type","value":"application/json"}],"headersSize":-1,"cookies":[],"queryString":[{"name":"foo","value":"bar"},{"name":"baz","value":"123"}],"postData":{"mimeType":"application/json","params":[],"text":"'hello world'"}}""")
    check:
      converted == expected

  test "convert - response":
    let converted = convert(getResponse())
    let expected = parseJson("""{"status":200,"statusText":"OK","httpVersion":"HTTP/1.1","headers":[{"name":"content-type","value":"application/json"}],"headersSize":-1,"cookies":[],"content":{"size":13,"compression":0,"mimeType":"application/json","text":"'Hello world'"},"bodySize":13,"redirectURL":""}""")
    check:
      converted == expected

  test "convert - request and response":
    let converted = convert(getRequest(), getResponse())
    let asJson = parseJson(converted)
    check:
      "log" in asJson

suite "async":

  test "convertResponse - response, async":
    # FIXME this line is throwing an exception
    let converted: JsonNode = waitFor(convertAsync(getAsyncResponse()))

    echo converted

    # ...

  test "convert - request and response, async":
    # TODO
    discard
