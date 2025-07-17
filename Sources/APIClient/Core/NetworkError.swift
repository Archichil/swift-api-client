import Foundation

/// An enumeration representing errors that can occur during network operations.
///
/// This enum defines common errors that may arise when making network requests,
/// such as invalid URLs, invalid responses, failed requests, and data conversion failures.
///
/// ## Example
/// ```swift
/// do {
///     let response = try await apiClient.sendRequest(someAPISpec)
/// } catch NetworkError.invalidURL {
///     print("Invalid URL")
/// } catch NetworkError.requestFailed(let statusCode) {
///     print("Request failed with status code: \(statusCode)")
/// } catch {
///     print("An unexpected error occurred: \(error)")
/// }
/// ```
public enum NetworkError: Error, LocalizedError {
    /// Indicates that the URL is invalid.
    ///
    /// This error occurs when the URL cannot be constructed from the provided string.
    case invalidURL

    /// Indicates that the response is invalid.
    ///
    /// This error occurs when the response cannot be cast to `HTTPURLResponse`.
    case invalidResponse

    /// Indicates that the request failed with a specific HTTP status code.
    ///
    /// - Parameter statusCode: The HTTP status code returned by the server.
    case requestFailed(statusCode: Int)

    /// Indicates that the data conversion failed.
    ///
    /// This error occurs when the response data cannot be decoded into the expected type.
    case decodingFailed(DecodingError)
    
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "The URL is invalid."
        case .invalidResponse: return "Invalid server response."
        case .requestFailed(let statusCode): return "Request failed with status code \(statusCode)."
        case .decodingFailed(let error): return "Decoding failed: \(error)"
        case .unknown(let error): return "Unknown error: \(error)"
        }
    }
}
