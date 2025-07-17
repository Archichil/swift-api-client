import Foundation

public extension APIClient {
    /// A protocol that defines the specification for an API request.
    ///
    /// Conforming types provide the necessary details to construct a URL request,
    /// including the endpoint, HTTP method, headers, body, and expected return type.
    ///
    /// ## Example
    /// ```swift
    /// struct MyAPISpec: APIClient.APISpecification {
    ///     var endpoint: String { "/my-endpoint" }
    ///     var method: HttpMethod { .get }
    ///     var returnType: DecodableType.Type { MyResponseType.self }
    ///     var headers: [String: String]? { ["Authorization": "Bearer token"] }
    ///     var body: Data? { nil }
    /// }
    /// ```
    protocol APISpecification {
        /// The API endpoint for the request.
        ///
        /// This is the path that will be appended to the base URL of the ``APIClient.swift``.
        var endpoint: String { get }

        /// The HTTP method for the request.
        var method: HttpMethod { get }

        /// The headers to include in the request.
        ///
        /// This is an optional dictionary of header fields and their values.
        var headers: [String: String]? { get }

        /// The body of the request.
        ///
        /// This is an optional `Data` object that will be sent as the HTTP body.
        var body: Data? { get }
    }
}
