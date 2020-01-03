import json, httpcore, unittest, uri
import expect
import http_har

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

test "convert":
  discard
