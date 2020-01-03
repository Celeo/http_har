import
  asynchttpserver,
  json,
  httpcore,
  httpclient,
  unittest,
  uri,
  streams
import expect
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

test "start":
  let s = start()
  expectEqual(s["log"]["version"].getStr(), "1.2")

test "convertHeaders":
  let headers = newHttpHeaders(@[("foo", "bar"), ("baz", "123")])
  let converted = convertHeaders(headers)
  expectEqual(converted[0]["name"].getStr(), "foo")
  expectEqual(converted[0]["value"].getStr(), "bar")
  expectEqual(converted[1]["name"].getStr(), "baz")
  expectEqual(converted[1]["value"].getStr(), "123")

test "convertCookies":
  let headers = newHttpHeaders(@[("something", "else"), ("Cookie", "foo=bar; baz=123")])
  let converted = convertCookies(headers)
  expectEqual(converted[0]["name"].getStr(), "foo")
  expectEqual(converted[0]["value"].getStr(), "bar")
  expectEqual(converted[1]["name"].getStr(), "baz")
  expectEqual(converted[1]["value"].getStr(), "123")

test "convertQueryString":
  let u = parseUri("http://localhost?foo=bar&baz=123")
  let converted = convertQueryString(u)
  expectEqual(converted[0]["name"].getStr(), "foo")
  expectEqual(converted[0]["value"].getStr(), "bar")
  expectEqual(converted[1]["name"].getStr(), "baz")
  expectEqual(converted[1]["value"].getStr(), "123")

test "convertRequest":
  let converted = convert(getRequest())
  let expected = parseJson("""{"bodySize":13,"method":"POST","url":"https://example.com?foo=bar&baz=123","httpVersion":"HTTP/1.1","headers":[{"name":"content-type","value":"application/json"}],"headersSize":-1,"cookies":[],"queryString":[{"name":"foo","value":"bar"},{"name":"baz","value":"123"}],"postData":{"mimeType":"application/json","params":[],"text":"'hello world'"}}""")
  expectTrue(converted == expected)

test "convertResponse":
  let converted = convert(getResponse())
  let expected = parseJson("""{"status":200,"statusText":"OK","httpVersion":"HTTP/1.1","headers":[{"name":"content-type","value":"application/json"}],"headersSize":-1,"cookies":[],"content":{"size":13,"compression":0,"mimeType":"application/json","text":"'Hello world'"},"bodySize":13,"redirectURL":""}""")
  expectTrue(converted == expected)

test "convertFull":
  let converted = convert(getRequest(), getResponse())
  let asJson = parseJson(converted)
  expectTrue("log" in asJson)
