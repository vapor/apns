import APNSwift
import Vapor

extension Application {
    public var apns: APNS {
        let apns = Application.APNS(application: self)
        self.lifecycle.use(apns)
        return apns
    }

    public struct APNS {

        struct APNSClientKey: StorageKey {
            typealias Value = APNSClient
        }

        public var client: APNSClient {
            guard let configuration = configuration else {
                fatalError("APNS not configured. Use app.apns.configuration = ...")
            }
            guard let client = self.application.storage[APNSClientKey.self] else {
                let client = APNSClient(configuration: configuration)
                self.application.storage[APNSClientKey.self] = client
                return client
            }
            return client
        }

        struct APNSConfigurationKey: StorageKey {
            typealias Value = APNSConfiguration
        }

        public var configuration: APNSConfiguration? {
            get {
                self.application.storage[APNSConfigurationKey.self]
            }
            nonmutating set {
                self.application.storage[APNSConfigurationKey.self] = newValue
            }
        }

        let application: Application
    }
}

extension Application.APNS: LifecycleHandler {
    public func shutdown(_ application: Application) {
         Task {
            try await client.shutdown()
        }
    }
}
