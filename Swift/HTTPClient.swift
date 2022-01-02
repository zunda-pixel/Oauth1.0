import Foundation

public enum HTTPMethod : String {
    case GET
    case POST
}

struct HTTPClient {
  private static func request(method: HTTPMethod, url: URL, headers: [String: String] = [:], queries: [String: String] = [:], timeout: Double = 60.0) async throws -> (Data, URLResponse) {
    var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
    
    urlComponents.queryItems = queries.map { .init(name: $0, value: $1)}
    
    var request = URLRequest(url: urlComponents.url!)
    request.httpMethod = method.rawValue
    request.allHTTPHeaderFields = headers
    request.timeoutInterval = timeout

    return try await URLSession.shared.data(for: request)
  }
  
  public static func get(url: URL, headers: [String: String] = [:], queries: [String: String] = [:]) async throws -> (Data, URLResponse) {
    return try await HTTPClient.request(method: .GET, url: url, headers: headers, queries: queries)
  }
  
  public static func post(url: URL, headers: [String: String] = [:], queries: [String: String] = [:]) async throws -> (Data, URLResponse) {
    return try await HTTPClient.request(method: .POST, url: url, headers: headers, queries: queries)
  }
}
