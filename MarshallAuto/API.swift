import Foundation

private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an unexpected response. Please try again."
        case .server(let message):
            return message
        }
    }
}

struct SessionResponse: Decodable {
    let csrfToken: String
    let authenticated: Bool
    let needsOnboarding: Bool
}

struct StateResponse: Decodable {
    let state: String
}

private struct ErrorResponse: Decodable {
    let error: String?
    let message: String?
}

final class API {
    static let baseURL = URL(string: "https://marshallautosanford.com")!
    private let delegate = NoRedirectDelegate()
    private let session: URLSession
    private let decoder: JSONDecoder

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func currentSession() async throws -> SessionResponse {
        try await get("/admin/mobile/session")
    }

    func dashboard() async throws -> Dashboard {
        try await get("/admin/dashboard/data")
    }

    func post(_ path: String, values: [String: String]) async throws -> StateResponse {
        let csrf = try await currentSession().csrfToken
        var request = makeRequest(path)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(csrf, forHTTPHeaderField: "X-CSRFToken")
        request.setValue(API.baseURL.absoluteString + "/", forHTTPHeaderField: "Referer")
        request.httpBody = try JSONEncoder().encode(values)
        return try await perform(request)
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await perform(makeRequest(path))
    }

    private func makeRequest(_ path: String) -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: API.baseURL)!.absoluteURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            let error = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.server(error?.error ?? error?.message ?? "Request failed (HTTP \(response.statusCode)).")
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }
}
