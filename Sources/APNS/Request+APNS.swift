import Vapor

extension Request {
    public var apns: APNS {
        .init(application: application,
              eventLoop: eventLoop,
              logger: logger)
    }
}
