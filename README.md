# http_har

A [Nim](https://nim-lang.org/) library to turn request and responses from the [standard library](https://nim-lang.org/docs/httpclient.html) into [HAR](https://en.wikipedia.org/wiki/HAR_(file_format)) v1.2 documents.

## Usage

### Download

Downloading can be done via

```sh
nimble install https://github.com/celeo/http_har
```

or putting `requires "https://github.com/celeo/http_har.git"` into your project's `.nimble` file and running `nimble build` or `nibmle test`.

### Use

Whenever your application has access to a `Request` and `Response`/`AsyncResponse`, you can feed those objects into a `convert` call via this library:

```nim
import http_har

...

let har = convert(req, resp)
echo har
```

## Testing

```sh
nimble test
```
