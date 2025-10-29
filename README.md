# Swift Logflare

A Swift package for sending logs to [Logflare](https://logflare.app/).

## Requirements

- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 8.0+
- Swift 6.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/grdsdev/swift-logflare.git", from: "0.1.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version and add to your target

## Usage

### Basic Setup

```swift
import Logflare

// Create client options
let options = ClientOptions(
    sourceToken: "your-source-token",
    apiKey: "your-api-key"
)

// Initialize the client
let logflare = try Logflare(options: options)
```

### Sending Events

#### Single Event
```swift
let event = [
    "message": "Hello from Swift!",
    "level": "info",
    "timestamp": Date().timeIntervalSince1970
]

let response = try await logflare.sendEvent(event)
print(response.message) // "Success"
```

#### Multiple Events
```swift
let events = [
    ["message": "Event 1", "level": "info"],
    ["message": "Event 2", "level": "error"],
    ["message": "Event 3", "level": "debug"]
]

let response = try await logflare.sendEvents(events)
print(response.message) // "Success"
```

### Error Handling

```swift
let options = ClientOptions(
    sourceToken: "your-source-token",
    apiKey: "your-api-key",
    onError: { payload, error in
        print("Logflare error: \(error.localizedDescription)")
    }
)

do {
    let response = try await logflare.sendEvent(event)
    print("Success: \(response.message)")
} catch {
    print("Failed to send event: \(error.localizedDescription)")
}
```

### Custom API URL

```swift
let options = ClientOptions(
    sourceToken: "your-source-token",
    apiKey: "your-api-key",
    apiURL: URL(string: "https://your-custom-logflare-instance.com")
)
```

## API Reference

### ClientOptions

- `sourceToken: String` - Your Logflare source token (required)
- `apiKey: String` - Your Logflare API key (required)
- `apiURL: URL?` - Custom API URL (optional, defaults to https://api.logflare.app)
- `onError: ((_ payload: [String: Any], _ error: Error) -> Void)?` - Error callback (optional)

### Logflare

- `init(options: ClientOptions) throws` - Initialize the client
- `sendEvent(_ event: [String: Any]) async throws(LogflareError) -> LogflareResponse` - Send a single event
- `sendEvents(_ batch: [[String: Any]]) async throws(LogflareError) -> LogflareResponse` - Send multiple events

### LogflareResponse

- `message: String` - Response message from Logflare

## License

This project is licensed under the MIT [License](./LICENSE).
