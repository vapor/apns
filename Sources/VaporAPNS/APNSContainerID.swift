
extension APNSContainers.ID {
    /// A default container ID available for use.
    ///
    /// If you are configuring both a production and development container, ``production`` and ``development`` are also available.
    ///
    /// - Note: You must configure this ID before using it by calling ``VaporAPNS/APNSContainers/use(_:eventLoopGroupProvider:responseDecoder:requestEncoder:byteBufferAllocator:as:isDefault:)``.
    /// - Important: The actual default ID to use in ``Vapor/Application/APNS/client`` when none is provided is the first configuration that doesn't specify a value of `false` for `isDefault:`.
    public static var `default`: APNSContainers.ID {
        return .init(string: "default")
    }
    
    /// An ID that can be used for the production APNs environment.
    ///
    /// - Note: You must configure this ID before using it by calling ``APNSContainers/use(_:eventLoopGroupProvider:responseDecoder:requestEncoder:byteBufferAllocator:as:isDefault:)``
    public static var production: APNSContainers.ID {
        return .init(string: "production")
    }
    
    /// An ID that can be used for the development (aka sandbox) APNs environment.
    ///
    /// - Note: You must configure this ID before using it by calling ``APNSContainers/use(_:eventLoopGroupProvider:responseDecoder:requestEncoder:byteBufferAllocator:as:isDefault:)``
    public static var development: APNSContainers.ID {
        return .init(string: "development")
    }
}
