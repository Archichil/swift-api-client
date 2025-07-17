import Foundation

/// Represents errors that occur during network operations and API interactions.
///
/// `NetworkError` provides a comprehensive set of error cases that can occur throughout
/// the network request lifecycle, from URL construction to response decoding. Each error
/// case includes contextual information to help with debugging and error handling.
///
/// This enum conforms to `LocalizedError` to provide user-friendly error descriptions
/// that can be displayed in UI or logged for debugging purposes.
///
/// ## Error Categories
/// - **URL Construction**: `invalidURL`
/// - **Response Validation**: `invalidResponse`, `requestFailed(statusCode:)`
/// - **Data Processing**: `decodingFailed(_:)`
/// - **Unexpected Issues**: `unknown(_:)`
///
/// ## Usage Examples
/// ```swift
/// // Basic error handling
/// do {
///     let user: User = try await apiClient.sendRequest(getUserSpec)
/// } catch NetworkError.invalidURL {
///     print("Check your endpoint configuration")
/// } catch NetworkError.requestFailed(let statusCode) {
///     handleHTTPError(statusCode: statusCode)
/// } catch NetworkError.decodingFailed(let decodingError) {
///     logDecodingIssue(decodingError)
/// } catch {
///     print("Unexpected error: \(error.localizedDescription)")
/// }
/// ```
///
/// ## Pattern Matching
/// ```swift
/// func handleNetworkError(_ error: NetworkError) {
///     switch error {
///     case .invalidURL:
///         // Handle URL construction issues
///     case .invalidResponse:
///         // Handle non-HTTP responses
///     case .requestFailed(let statusCode) where statusCode == 401:
///         // Handle authentication errors
///     case .requestFailed(let statusCode) where (400..<500).contains(statusCode):
///         // Handle client errors
///     case .requestFailed(let statusCode) where (500..<600).contains(statusCode):
///         // Handle server errors
///     case .decodingFailed(let decodingError):
///         // Handle JSON parsing issues
///     case .unknown(let underlyingError):
///         // Handle unexpected errors
///     }
/// }
/// ```
public enum NetworkError: Error, LocalizedError {
    /// The URL could not be constructed from the provided endpoint and base URL.
    ///
    /// This error typically occurs when:
    /// - The endpoint string contains invalid characters
    /// - The base URL and endpoint combination results in a malformed URL
    /// - URL encoding issues prevent proper URL construction
    ///
    /// **Resolution**: Verify that your endpoint strings are properly formatted
    /// and that the base URL is valid.
    case invalidURL

    /// The server response is not a valid HTTP response.
    ///
    /// This error occurs when:
    /// - The response cannot be cast to `HTTPURLResponse`
    /// - The network layer returns a non-HTTP response type
    /// - Protocol-level issues prevent proper HTTP response handling
    ///
    /// **Resolution**: This typically indicates a fundamental networking issue
    /// or an unexpected response type from the server.
    case invalidResponse

    /// The HTTP request failed with a specific status code.
    ///
    /// This error is thrown for any HTTP status code outside the success range (200-299).
    /// The associated status code provides context about the specific failure type.
    ///
    /// - Parameter statusCode: The HTTP status code returned by the server.
    ///
    /// ## Common Status Codes
    /// - **4xx Client Errors**: Authentication, authorization, or request format issues
    /// - **5xx Server Errors**: Internal server problems or service unavailability
    ///
    /// **Resolution**: Handle different status code ranges appropriately based on
    /// your application's error handling strategy.
    case requestFailed(statusCode: Int)

    /// JSON decoding failed when parsing the response data.
    ///
    /// This error wraps the underlying `DecodingError` and occurs when:
    /// - The response JSON structure doesn't match the expected `Decodable` type
    /// - Required fields are missing from the JSON response
    /// - Data type mismatches between JSON and Swift types
    /// - The response contains invalid JSON syntax
    ///
    /// - Parameter error: The underlying `DecodingError` with detailed failure information.
    ///
    /// **Resolution**: Check your data models against the actual API response format,
    /// or examine the underlying `DecodingError` for specific field-level issues.
    case decodingFailed(DecodingError)
    
    /// An unexpected error occurred that doesn't fit other categories.
    ///
    /// This error wraps any other `Error` that may occur during network operations,
    /// including:
    /// - Network connectivity issues
    /// - SSL/TLS certificate problems
    /// - Request timeout errors
    /// - System-level networking failures
    ///
    /// - Parameter error: The underlying error that caused the failure.
    ///
    /// **Resolution**: Examine the underlying error for specific details about
    /// the failure and implement appropriate retry or fallback mechanisms.
    case unknown(Error)
    
    /// A localized, human-readable description of the error.
    ///
    /// This property provides user-friendly error messages that can be displayed
    /// in user interfaces or logged for debugging purposes. Each error case
    /// returns a descriptive message that includes relevant context.
    ///
    /// ## Example Messages
    /// - `invalidURL`: "The URL is invalid."
    /// - `requestFailed(statusCode: 404)`: "Request failed with status code 404."
    /// - `decodingFailed(...)`: "Decoding failed: [detailed error information]"
    ///
    /// ```swift
    /// catch let networkError as NetworkError {
    ///     showAlert(message: networkError.localizedDescription)
    /// }
    /// ```
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .invalidResponse:
            return "Invalid server response."
        case .requestFailed(let statusCode):
            return "Request failed with status code \(statusCode)."
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
