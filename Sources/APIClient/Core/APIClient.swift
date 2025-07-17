import Foundation

/// A client for making network requests to an API.
///
/// This struct provides methods to send requests to an API and handle responses.
/// It supports decoding responses into `Decodable` types and handles common network errors.
///
/// ## Example
/// ```swift
/// let baseURL = URL(string: "https://api.example.com")!
/// let apiClient = APIClient(baseURL: baseURL)
///
/// Task {
///     do {
///         let response = try await apiClient.sendRequest(someAPISpec)
///         print(response)
///     } catch {
///         print("Error: \(error)")
///     }
/// }
/// ```
public struct APIClient {
    /// The base URL for the API.
    private let baseURL: URL

    /// The URL session used to perform network requests.
    private let urlSession: URLSession
    
    /// JSONDecoder used to decode response data.
    private let decoder: JSONDecoder

    /// Initializes a new `APIClient` instance.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for the API.
    ///   - urlSession: The URL session to use for network requests. Defaults to `URLSession.shared`.
    public init(
        baseURL: URL,
        urlSession: URLSession = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.decoder = decoder
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    /// Sends a request to the API based on the provided specification.
    ///
    /// This method constructs a URL request from the `APISpec`, sends it, and decodes the response into the specified `Decodable` type.
    ///
    /// - Parameter apiSpec: The API specification that defines the request to be sent.
    /// - Returns: A decoded response of type `DecodableType`.
    /// - Throws: An error if the request fails, the response is invalid, or decoding fails.
    ///
    /// ## Example
    /// ```swift
    /// let response = try await apiClient.sendRequest(someAPISpec)
    /// ```
    public func sendRequest<T: Decodable>(_ specification: APISpecification) async throws -> T {
        guard let url = URL(string: specification.endpoint, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
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
        
        if T.self == Data.self, let rawData = data as? T {
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

    /// Validates the HTTP response from the API.
    ///
    /// This method checks if the response is a valid `HTTPURLResponse` and if the status code is within the success range (200-299).
    ///
    /// - Parameters:
    ///   - data: The data returned by the API.
    ///   - response: The URL response returned by the API.
    /// - Throws: An error if the response is invalid or the status code indicates a failure.
    private func handleResponse(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }
}
