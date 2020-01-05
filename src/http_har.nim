import
  asyncdispatch,
  asynchttpserver,
  httpclient,
  httpcore,
  json,
  sequtils,
  strutils,
  tables,
  times,
  uri

proc start*(): JsonNode =
  ## Start the HAR data.
  %*{
    "log": {
      "version": "1.2",
      "creator": {
        "name": "",
        "version": ""
      },
      "entries": []
    }
  }

proc convertHeaders*(headers: HttpHeaders): seq[JsonNode] =
  ## Convert headers from a `Request` or `(Async)Response` into `JsonNode`s.
  for (k, v) in headers.pairs():
    result.add(%*{
      "name": k,
      "value": v
    })

proc convertCookies*(headers: HttpHeaders): seq[JsonNode] =
  ## Convert cookies from headers from a `Request` or `(Async)Response` into `JsonNode`s.
  let cookies = headers.table.getOrDefault("cookie", @[])
  for val in cookies:
    for cookie in val.split(';'):
      let parts = cookie.split('=')
      result.add(%*{
        "name": parts[0].strip(),
        "value": parts[1].strip()
      })

proc convertQueryString*(uri: Uri): seq[JsonNode] =
  ## Convert query params into `JsonNode`s.
  if uri.query != "":
    result = uri.query.split("&")
      .mapIt(it.split('='))
      .mapIt(%*{
        "name": it[0],
        "value": it[1]
      })

proc convert*(request: Request): JsonNode =
  ## Convert a `Request` into a `JsonNode`.
  result = %*{
    "bodySize": request.body.len(),
    "method": $request.reqMethod,
    "url": $request.url,
    "httpVersion": request.protocol.orig,
    "headers": convertHeaders(request.headers),
    "headersSize": -1,
    "cookies": convertCookies(request.headers),
    "queryString": convertQueryString(request.url)
  }
  if request.body.len() > 0:
    result["postData"] = %*{
      "mimeType": request.headers.table.getOrDefault("content-type", @[""]).join("; "),
      "params": [],
      "text": request.body
    }

proc convert*(response: Response): JsonNode =
  ## Convert a `Response` into a `JsonNode`.
  %*{
    "status": response.status[0..2].parseInt(),
    "statusText": response.status[4..^1],
    "httpVersion": "HTTP/1.1",
    "headers": convertHeaders(response.headers),
    "headersSize": -1,
    "cookies": convertCookies(response.headers),
    "content": {
      "size": response.body.len(),
      "compression": 0,
      "mimeType": response.headers.table.getOrDefault("content-type", @[""]).join("; "),
      "text": response.body
    },
    "bodySize": response.body.len(),
    "redirectURL": ""
  }

proc convertAsync*(response: AsyncResponse): Future[JsonNode] {.async.} =
  ## Convert a `AsyncResponse` into a `JsonNode`.
  ##
  ## Since this object is asynchronous in design, this method is also
  ## async so that the data can be processed asynchronously. You'll need
  ## to handle this implementing in your application, whether that's
  ## `await`ing the call to this proc, or adding a `waitFor` if not in
  ## asnychronous environment.
  let body = await response.body()
  result = %*{
    "status": response.status[0..2].parseInt(),
    "statusText": response.status[4..^1],
    "httpVersion": "HTTP/1.1",
    "headers": convertHeaders(response.headers),
    "headersSize": -1,
    "cookies": convertCookies(response.headers),
    "content": {
      "size": body.len(),
      "compression": 0,
      "mimeType": response.headers.table.getOrDefault("content-type", @[""]).join("; "),
      "text": body
    },
    "bodySize": body.len(),
    "redirectURL": ""
  }

proc convert*(request: Request, response: Response): string =
  ## Convert a `Request` and `Response`.
  var data = start()
  var entry = %*{
    "startedDateTime": now().format("yyyy-MM-dd'T'hh:mm:ss'.0'zzz"),
    "request": convert(request),
    "response": convert(response),
    "cache": {},
    "timings": {
      "send": 0,
      "wait": 0,
      "receive": 0,
    }
  }
  data["log"]["entries"].add(entry)
  $data

proc convertAsync*(request: Request, response: AsyncResponse): Future[string] {.async.} =
  ## Convert a `Request` and `AsyncResponse`.
  ##
  ## See the notes on the `convertAsync` proc for more information.
  var data = start()
  var entry = %*{
    "startedDateTime": now().format("yyyy-MM-dd'T'hh:mm:ss'.0'zzz"),
    "request": convert(request),
    "response": await convertAsync(response),
    "cache": {},
    "timings": {
      "send": 0,
      "wait": 0,
      "receive": 0,
    }
  }
  data["log"]["entries"].add(entry)
  result = $data
