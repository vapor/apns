import APNS
import NIOConcurrencyHelpers
import Vapor

extension Application {
    public var apns: APNS {
        return .init(application: self)
    }

    public struct APNS {

        // Synchronize access across threads.
        private var lock: NIOLock

        struct ContainersKey: StorageKey, LockKey {
            typealias Value = APNSContainers
        }

        public var containers: APNSContainers {
            if let existingContainers = self.application.storage[ContainersKey.self] {
                return existingContainers
            } else {
                let lock = self.application.locks.lock(for: ContainersKey.self)
                lock.lock()
                defer { lock.unlock() }
                let new = APNSContainers()
                self.application.storage.set(ContainersKey.self, to: new) {
                    $0.syncShutdown()
                }
                return new
            }
        }

        public var client: APNSGenericClient {
            guard let container = containers.container() else {
                fatalError("No default APNS container configured.")
            }
            return container.client
        }

        public func client(_ id: APNSContainers.ID = .default) -> APNSGenericClient {
            guard let container = containers.container(for: id) else {
                fatalError("No APNS container for \(id).")
            }
            return container.client
        }

        let application: Application

        public init(application: Application) {
            self.application = application
            self.lock = .init()
        }
    }
}
