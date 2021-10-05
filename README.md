# SimpleHTTP

A description of this package.

## Usage

```swift
let client = HTTPClient(
  url: URL(string: "https://example.com")!,
  adapters: [myCustomAuthAdapter],
  interceptors: [.retrier()]
)

let tasks = try await client.request(
  Endpoint(
    path: "/tasks"
    method: .get
  )
).decoded(to: [Task].self)
```
