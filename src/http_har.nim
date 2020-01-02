import asynchttpserver,
  httpclient,
  httpcore,
  json,
  strutils,
  times

proc start(): JsonNode =
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

proc convertHeaders(headers: HttpHeaders): (seq[JsonNode], int) =
  var headers: seq[JsonNode] = @[]
  for (k, v) in headers.pairs():
    headers.add(%*{
      "name": k,
      "value": v
    })
  # TODO calculate size
  (headers, 0)

proc convert*(request: Request): JsonNode =
  let (headers, headerSize) = convertHeaders(request.headers)
  %*{
    "bodySize": request.body.len(),
    "method": $request.reqMethod,
    "url": $request.url,
    "httpVersion": "HTTP/1.1",
    "headers": headers,
    "headersSize": headerSize,
    "cookies": [], # TODO
    "queryString": [] # TODO, data in 'request.query'
  }

proc convert*(response: Response): JsonNode =
  let (headers, headerSize) = convertHeaders(response.headers)
  %*{
    "status": response.status.parseInt(),
    "statusText": ($response.code()).split(" ")[1..^1].join(" "),
    "httpVersion": "HTTP/1.1",
    "headers": headers,
    "headersSize": headerSize,
    "cookies": [], # TODO
    "content": {}, # TODO
    "bodySize": 0, # TODO
    "redirectURL": ""
  }

proc convert*(request: Request, response: Response): string =
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
  data["entries"].add(entry)
  $data
