class SessionsApiClient {
    private let sessionNotFoundError = AccessCheckoutClientError.sessionNotFound(message: "Failed to find link \(ApiLinks.sessions.result) in response")

    private var discovery: SessionsApiDiscovery
    private var urlRequestFactory: PaymentsCvcSessionURLRequestFactory
    private var restClient: RestClient
    private var apiResponseLinkLookup: ApiResponseLinkLookup

    init() {
        self.discovery = SessionsApiDiscovery()
        self.urlRequestFactory = PaymentsCvcSessionURLRequestFactory()
        self.restClient = RestClient()
        self.apiResponseLinkLookup = ApiResponseLinkLookup()
    }

    init(discovery: SessionsApiDiscovery) {
        self.discovery = discovery
        self.urlRequestFactory = PaymentsCvcSessionURLRequestFactory()
        self.restClient = RestClient()
        self.apiResponseLinkLookup = ApiResponseLinkLookup()
    }

    init(discovery: SessionsApiDiscovery, urlRequestFactory: PaymentsCvcSessionURLRequestFactory, restClient: RestClient) {
        self.discovery = discovery
        self.urlRequestFactory = urlRequestFactory
        self.restClient = restClient
        self.apiResponseLinkLookup = ApiResponseLinkLookup()
    }

    func createSession(baseUrl: String, merchantId: String, cvv: String, completionHandler: @escaping (Result<String, AccessCheckoutClientError>) -> Void) {
        discovery.discover(baseUrl: baseUrl) { result in
            switch result {
            case .success(let endPointUrl):
                self.fireRequest(endPointUrl: endPointUrl, merchantId: merchantId, cvv: cvv) { result in
                    switch result {
                    case .success(let response):
                        if let session = self.apiResponseLinkLookup.lookup(link: ApiLinks.sessions.result, in: response) {
                            completionHandler(.success(session))
                        } else {
                            completionHandler(.failure(self.sessionNotFoundError))
                        }
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    private func fireRequest(endPointUrl: String, merchantId: String, cvv: String, completionHandler: @escaping (Swift.Result<ApiResponse, AccessCheckoutClientError>) -> Void) {
        let request = createRequest(endPointUrl: endPointUrl, merchantId: merchantId, cvv: cvv)

        restClient.send(urlSession: URLSession.shared, request: request, responseType: ApiResponse.self) { result in
            completionHandler(result)
        }
    }

    private func createRequest(endPointUrl: String, merchantId: String, cvv: String) -> URLRequest {
        return urlRequestFactory.create(url: endPointUrl, cvv: cvv, merchantIdentity: merchantId, bundle: Bundle(for: SessionsApiClient.self))
    }
}
