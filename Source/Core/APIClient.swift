import Foundation

/// A robust networking client for making API requests with automatic response handling.
///
/// `APIClient` provides a high-level interface for performing HTTP requests to REST APIs.
/// It handles URL construction, request configuration, response validation, and automatic
/// JSON decoding with comprehensive error handling.
///
/// ## Key Features
/// - Automatic JSON decoding with snake_case to camelCase conversion
/// - Built-in response validation and error handling
/// - Support for raw `Data` responses when needed
/// - Configurable URL session and JSON decoder
/// - Type-safe request/response handling
///
/// ## Basic Usage
/// ```swift
/// let client = APIClient(baseURL: URL(string: "https://api.example.com")!)
///
/// // Define your API specification
/// let userSpec = APISpecification(
///     endpoint: "/users/123",
///     method: .GET,
///     headers: ["Authorization": "Bearer token"]
/// )
///
/// // Make the request
/// let user: User = try await client.sendRequest(userSpec)
/// ```
///
/// ## Error Handling
/// ```swift
/// do {
///     let data: UserResponse = try await client.sendRequest(spec)
///     // Handle success
/// } catch NetworkError.requestFailed(let statusCode) {
///     print("Request failed with status: \(statusCode)")
/// } catch NetworkError.decodingFailed(let error) {
///     print("Failed to decode response: \(error)")
/// } catch {
///     print("Unexpected error: \(error)")
/// }
/// ```
public struct APIClient: Sendable {
    /// The base URL for all API requests.
    ///
    /// All endpoint paths in `APISpecification` will be resolved relative to this URL.
    private let baseURL: URL

    /// The URL session used for network requests.
    ///
    /// Defaults to `URLSession.shared` but can be customized for testing or
    /// specific configuration requirements.
    private let urlSession: URLSession
    
    /// The JSON decoder for response data.
    ///
    /// Configured by default to convert snake_case keys to camelCase to match
    /// Swift naming conventions.
    private let decoder: JSONDecoder

    /// Creates a new API client instance.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all API requests. Endpoint paths will be appended to this URL.
    ///   - urlSession: The URL session for network requests. Defaults to `URLSession.shared`.
    ///   - decoder: The JSON decoder for responses. Defaults to a new `JSONDecoder` with snake_case conversion.
    ///   - useSnakeCaseConversion: Whether to automatically convert snake_case keys to camelCase. Defaults to `true`.
    ///
    /// ## Example
    /// ```swift
    /// // Basic initialization with snake_case conversion
    /// let client = APIClient(baseURL: URL(string: "https://api.example.com")!)
    ///
    /// // Disable snake_case conversion
    /// let client = APIClient(
    ///     baseURL: baseURL,
    ///     useSnakeCaseConversion: false
    /// )
    ///
    /// // Custom decoder with snake_case conversion
    /// let customDecoder = JSONDecoder()
    /// customDecoder.dateDecodingStrategy = .iso8601
    /// let client = APIClient(
    ///     baseURL: baseURL,
    ///     decoder: customDecoder,
    ///     useSnakeCaseConversion: true
    /// )
    /// ```
    public init(
        baseURL: URL,
        urlSession: URLSession = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder(),
        useSnakeCaseConversion: Bool = true
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.decoder = decoder
        
        if useSnakeCaseConversion {
            self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        }
    }

    /// Executes an API request and returns the decoded response.
    ///
    /// This method performs the complete request lifecycle:
    /// 1. Constructs the full URL from the base URL and specification endpoint
    /// 2. Creates and configures the HTTP request with headers, method, and body
    /// 3. Executes the network request with a 30-second timeout
    /// 4. Validates the HTTP response status code (200-299 range)
    /// 5. Decodes the response data into the specified type
    ///
    /// - Parameter specification: The API specification defining the request details
    ///   (endpoint, HTTP method, headers, and body).
    /// - Returns: The decoded response of the specified `Decodable` type.
    /// - Throws:
    ///   - `NetworkError.invalidURL` if the endpoint URL cannot be constructed
    ///   - `NetworkError.invalidResponse` if the response is not an HTTP response
    ///   - `NetworkError.requestFailed(statusCode:)` for non-2xx HTTP status codes
    ///   - `NetworkError.decodingFailed(_:)` if JSON decoding fails
    ///   - `NetworkError.unknown(_:)` for other unexpected errors
    ///
    /// ## Examples
    /// ```swift
    /// // Decode JSON response
    /// let users: [User] = try await client.sendRequest(getUsersSpec)
    ///
    /// // Get raw data (bypasses JSON decoding)
    /// let imageData: Data = try await client.sendRequest(getImageSpec)
    ///
    /// // Handle specific response types
    /// let response: APIResponse<User> = try await client.sendRequest(createUserSpec)
    /// ```
    ///
    /// ## Special Behavior
    /// - When the expected return type is `Data`, the method returns the raw response
    ///   data without attempting JSON decoding.
    /// - All requests have a 30-second timeout and use protocol cache policy.
    /// - JSON decoding automatically converts snake_case keys to camelCase.
    public func sendRequest<T: Decodable>(_ specification: APISpecification) async throws -> T {
        let url = try constructURL(from: specification)
        var request = URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: TimeInterval(floatLiteral: 30.0)
        )
        request.httpMethod = specification.method.rawValue
        request.httpBody = specification.body
        request.allHTTPHeaderFields = specification.headers

        let (data, response) = try await urlSession.data(for: request)
        try handleResponse(response: response)
        
        // Raw Data don't have to be decoded
        if let rawData: T = data as? T {
            return rawData
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingFailed(decodingError)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    /// Constructs the full URL for a request from the specification.
    ///
    /// This method handles URL construction with support for query parameters,
    /// combining the base URL with the endpoint and optional query parameters.
    ///
    /// - Parameter specification: The API specification containing endpoint and query parameters
    /// - Returns: The fully constructed URL for the request
    /// - Throws: `NetworkError.invalidURL` if the URL cannot be constructed
    private func constructURL(from specification: APISpecification) throws(NetworkError) -> URL {
        guard let baseWithEndpoint = URL(string: specification.endpoint, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        if let queryParameters = specification.queryParameters, !queryParameters.isEmpty {
            guard var components = URLComponents(url: baseWithEndpoint, resolvingAgainstBaseURL: true) else {
                throw NetworkError.invalidURL
            }
            
            components.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            
            guard let finalURL = components.url else {
                throw NetworkError.invalidURL
            }
            
            return finalURL
        }
        
        return baseWithEndpoint
    }

    /// Validates the HTTP response status and type.
    ///
    /// Ensures the response is a valid `HTTPURLResponse` and that the status code
    /// indicates success (200-299 range). This method is called internally by
    /// `sendRequest(_:)` to validate responses before attempting to decode them.
    ///
    /// - Parameter response: The URL response to validate.
    /// - Throws:
    ///   - `NetworkError.invalidResponse` if the response is not an `HTTPURLResponse`
    ///   - `NetworkError.requestFailed(statusCode:)` if the status code is outside the 200-299 range
    private func handleResponse(response: URLResponse) throws(NetworkError) {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }
}
