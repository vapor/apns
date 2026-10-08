import Vapor

/// A throwaway EC P-256 key used purely to satisfy JWT configuration in tests.
///
/// It is not registered with Apple and cannot authenticate against APNs.
let appleECP8PrivateKey = """
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg2sD+kukkA8GZUpmm
    jRa4fJ9Xa/JnIG4Hpi7tNO66+OGgCgYIKoZIzj0DAQehRANCAATZp0yt0btpR9kf
    ntp4oUUzTV0+eTELXxJxFvhnqmgwGAm1iVW132XLrdRG/ntlbQ1yzUuJkHtYBNve
    y+77Vzsd
    -----END PRIVATE KEY-----
    """

/// Runs `test` against a freshly made testing `Application`, shutting it down afterwards.
///
/// The shutdown is awaited rather than fired off in a detached `Task` so that APNs containers
/// are torn down before the test returns.
func withApp(_ test: (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    do {
        try await test(app)
    } catch {
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
