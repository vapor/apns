extension APNSClients.ID {
    /// A default client ID available for use.
    ///
    /// If you are configuring both a production and development client, ``production`` and ``development`` are also available.
    ///
    /// - Note: You must configure this ID before using it by calling ``APNSClients/use(_:eventLoopGroupProvider:responseDecoder:requestEncoder:byteBufferAllocator:as:isDefault:)``.
    /// - Important: The actual default ID to use in ``APNSClients/client`` when none is provided is the first configuration that doesn't specify a value of `false` for `isDefault:`.
    public static var `default`: APNSClients.ID {
        return .init(string: "default")
    }

    /// An ID that can be used for the production APNs environment.
    ///
    /// - Note: You must configure this ID before using it by calling ``APNSClients/use(_:eventLoopGroupProvider:responseDecoder:requestEncoder:byteBufferAllocator:as:isDefault:)``
    public static var production: APNSClients.ID {
        return .init(string: "production")
    }

    /// An ID that can be used for the development (aka sandbox) APNs environment.
    ///
    /// - Note: You must configure this ID before using it by calling ``APNSClients/use(_:eventLoopGroupProvider:responseDecoder:requestEncoder:byteBufferAllocator:as:isDefault:)``
    public static var development: APNSClients.ID {
        return .init(string: "development")
    }
}
