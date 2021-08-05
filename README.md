# SimpleHTTP

A description of this package.

## Usage

```swift
let client = HTTPClient(
  url: URL(string: "https://example.com")!,
  adapters: [myCustomAuthAdapter],
  interceptors: [myCustomRetrier]
)

client.request(
  Endpoint(
    path: "/tasks"
    method: .get
  )
) { result in 
  switch result.decoded(to: [Task].self) {
  case .success(let tasks):
    // use the task array
  case .failure(let error):
    // present the error for the user?
  }
}
```
