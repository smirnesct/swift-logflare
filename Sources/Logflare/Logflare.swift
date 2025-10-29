import Foundation

// MARK: - Client Options

public struct ClientOptions {
  /// UUID identifier for source
  public let sourceToken: String
  /// API key retrieved from service
  public let apiKey: String
  /// Configurable URL for the server endpoint
  public let apiURL: URL?
  /// Optional callback function to handle any errors returned by server
  public let onError: ((_ payload: [String: Any], _ error: Error) -> Void)?

  public init(
    sourceToken: String,
    apiKey: String,
    apiURL: URL? = nil,
    onError: ((_ payload: [String: Any], _ error: Error) -> Void)? = nil
  ) {
    self.sourceToken = sourceToken
    self.apiKey = apiKey
    self.apiURL = apiURL
    self.onError = onError
  }
}

// MARK: - Logflare Client

public struct LogflareResponse: Sendable {
  public let message: String
}

public class Logflare {
  private let sourceToken: String
  private let apiKey: String
  private let apiURL: URL
  private let onError: ((_ payload: [String: Any], _ error: Error) -> Void)?

  public init(options: ClientOptions) throws {
    guard !options.sourceToken.isEmpty else {
      throw LogflareError("Logflare API source token is NOT configured!")
    }

    guard !options.apiKey.isEmpty else {
      throw LogflareError("Logflare API logging transport api key is NOT configured!")
    }

    self.sourceToken = options.sourceToken
    self.apiKey = options.apiKey
    self.apiURL = options.apiURL ?? URL(string: "https://api.logflare.app")!
    self.onError = options.onError
  }

  @discardableResult
  public func sendEvent(_ event: [String: Any]) async throws(LogflareError) -> LogflareResponse {
    try await sendEvents([event])
  }

  @discardableResult
  public func sendEvents(_ batch: [[String: Any]]) async throws(LogflareError) -> LogflareResponse {
    let path = "/api/logs?api_key=\(apiKey)&source=\(sourceToken)"
    let payload = ["batch": batch]

    guard let url = URL(string: path, relativeTo: apiURL) else {
      throw LogflareError("Invalid URL for Logflare API")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    } catch {
      throw LogflareError(
        "JSON serialization failed: \(error.localizedDescription)", underlyingError: error)
    }

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      let responseJSON = try? JSONSerialization.jsonObject(with: data)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw LogflareError(
          "Invalid response from Logflare API", response: response, data: responseJSON)
      }

      guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
        throw LogflareError(
          "Network response was not ok for \"\(url.absoluteString)\"",
          response: httpResponse,
          data: responseJSON
        )
      }

      guard let message = (responseJSON as? [String: Any])?["message"] as? String else {
        throw LogflareError(
          "Invalid JSON response from Logflare API", response: response, data: responseJSON)
      }

      return LogflareResponse(message: message)

    } catch {
      let logflareError: LogflareError

      if let error = error as? LogflareError {
        logflareError = error
      } else {
        logflareError = LogflareError(
          "Unknown error: \(error.localizedDescription)", underlyingError: error)
      }

      #if DEBUG
        print("Logflare API request failed: \(logflareError.localizedDescription)")
      #endif

      onError?(payload, logflareError)

      throw logflareError
    }
  }
}

// MARK: - Logflare Errors

public struct LogflareError: LocalizedError, @unchecked Sendable {
  public let name = "LogflareError"

  public let errorDescription: String?
  public let underlyingError: Error?
  public let response: URLResponse?
  public let data: Any?

  init(
    _ message: String,
    underlyingError: Error? = nil,
    response: URLResponse? = nil,
    data: Any? = nil
  ) {
    self.errorDescription = message
    self.underlyingError = underlyingError
    self.response = response
    self.data = data
  }
}
