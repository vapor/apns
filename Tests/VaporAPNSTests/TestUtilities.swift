import APNS
import APNSCore
import Crypto
import VaporAPNS

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

func testAuthenticationMethod() throws -> APNSClientConfiguration.AuthenticationMethod {
    .jwt(
        privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
        keyIdentifier: "9UC9ZLQ8YW",
        teamIdentifier: "ABBM6U9RM5"
    )
}

func testConfiguration(environment: APNSEnvironment = .development) throws -> APNSClientConfiguration {
    APNSClientConfiguration(authenticationMethod: try testAuthenticationMethod(), environment: environment)
}

/// Runs `test` with a fresh ``APNSContainers``, shutting its clients down afterwards.
func withContainers(_ test: (APNSContainers) async throws -> Void) async throws {
    let containers = APNSContainers()
    do {
        try await test(containers)
    } catch {
        await containers.shutdown()
        throw error
    }
    await containers.shutdown()
}

extension APNSContainers.ID {
    static var custom: APNSContainers.ID {
        .init(string: "custom")
    }
}
