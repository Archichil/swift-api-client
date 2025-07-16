# Swift API Client

A modern, type-safe Swift networking library designed for building robust and maintainable API clients. Features automatic JSON decoding, comprehensive error handling, and a declarative request specification pattern.

## Features

✨ **Type-Safe Requests** - Protocol-based API specifications ensure compile-time safety  
🔄 **Automatic JSON Decoding** - Built-in snake_case to camelCase conversion  
🚨 **Comprehensive Error Handling** - Detailed error types for better debugging  
⚡ **Async/Await Support** - Modern Swift concurrency for clean, readable code  
🎯 **Flexible Configuration** - Customizable URL sessions and JSON decoders  
📱 **Multi-Platform** - Supports iOS 13+ and macOS 10.15+

## Installation

### Swift Package Manager

Add this package to your project by adding the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Archichil/swift-api-client.git", from: "1.0.0")
]
```

Or add it through Xcode by going to **File → Add Package Dependencies** and entering the repository URL.

## Quick Start

### 1. Create an API Client

```swift
import APIClient

let baseURL = URL(string: "https://api.example.com")!
let client = APIClient(baseURL: baseURL)
```

### 2. Define API Specifications

```swift
// You can use enum for multiple endpoints
struct GetUserSpec: APIClient.APISpecification {
    let userId: Int
    
    var endpoint: String { "/users/\(userId)" }
    var method: APIClient.HttpMethod { .get }
    var returnType: DecodableType.Type { User.self }
    var headers: [String: String]? { 
        ["Authorization": "Bearer \(authToken)"]
    }
    var body: Data? { nil }
}
```

### 3. Make Requests

```swift
let getUserSpec = GetUserSpec(userId: 123)

do {
    let user: User = try await client.sendRequest(getUserSpec)
    print("User: \(user.name)")
} catch NetworkError.requestFailed(let statusCode) {
    print("Request failed with status: \(statusCode)")
} catch NetworkError.decodingFailed(let error) {
    print("Decoding failed: \(error)")
} catch {
    print("Unexpected error: \(error)")
}
```

## API Reference

### APIClient

The main client class for making network requests:

```swift
public struct APIClient {
    public init(baseURL: URL, urlSession: URLSession = URLSession.shared)
    public func sendRequest<T: Decodable>(_ specification: APISpecification) async throws -> T
}
```

### APISpecification Protocol

Define your API requests by conforming to this protocol:

```swift
protocol APISpecification {
    var endpoint: String { get }
    var method: HttpMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
}
```

### HTTP Methods

Supported HTTP methods:

```swift
enum HttpMethod: String, CaseIterable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
}
```

### Error Handling

The library provides comprehensive error types:

```swift
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int)
    case decodingFailed(DecodingError)
    case unknown(Error)
}
```

## Examples

### GET Request

```swift
struct GetUsersSpec: APIClient.APISpecification {
    var endpoint: String { "/users" }
    var method: APIClient.HttpMethod { .get }
    var headers: [String: String]? { 
        ["Accept": "application/json"]
    }
    var body: Data? { nil }
}

let users: [User] = try await client.sendRequest(GetUsersSpec())
```

### POST Request with JSON Body

```swift
struct CreateUserSpec: APIClient.APISpecification {
    let user: CreateUserRequest
    
    var endpoint: String { "/users" }
    var method: APIClient.HttpMethod { .post }
    var headers: [String: String]? {
        [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(authToken)"
        ]
    }
    var body: Data? {
        try? JSONEncoder().encode(user)
    }
}

let newUser: User = try await client.sendRequest(CreateUserSpec(user: userRequest))
```

### Raw Data Response

For non-JSON responses (like images or files):

```swift
let imageData: Data = try await client.sendRequest(GetImageSpec(imageId: "123"))
```

## Advanced Usage

### Custom URL Session

```swift
let customSession = URLSession(configuration: .ephemeral)
let client = APIClient(baseURL: baseURL, urlSession: customSession)
```

### Custom JSON Decoder

```swift
let customDecoder = JSONDecoder()
customDecoder.dateDecodingStrategy = .iso8601

let client = APIClient(baseURL: baseURL, decoder: customDecoder)
```
> :warning: .convertFromSnakeCase decoding strategy is used by default!

## Requirements

- iOS 13.0+ / macOS 10.15+
- Xcode 16.0+

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.
