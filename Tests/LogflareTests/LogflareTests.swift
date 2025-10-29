import Testing
@testable import Logflare

@Test func example() async throws {
    let client = try Logflare(options: ClientOptions(
        sourceToken: "test",
        apiKey: "test"
    ))

    try await client.sendEvent(["message": "test"])
}
