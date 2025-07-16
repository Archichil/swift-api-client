open class APIService {
    public var apiClient: APIClient?

    public init(apiClient: APIClient?) {
        self.apiClient = apiClient
    }
}
