import Appboy_iOS_SDK
import Segment
import Segment_Appboy
import KsApi

public extension Analytics {
  static func configuredClient() -> Analytics {
    let configuration = AnalyticsConfiguration(writeKey: Secrets.Segment.writeKey)
    configuration.trackApplicationLifecycleEvents = true // We should deprecate our own tracking for these events.
    configuration.recordScreenViews = true // Test that this does not interfere with our own swizzling.

    configuration.use(SEGAppboyIntegrationFactory.instance())

    Analytics.setup(with: configuration)

    return Analytics.shared()
  }
}

extension Analytics: TrackingClientType {
  /// Call the similarly named function on Segment's `Analytics` type.
  public func track(event: String, properties: [String : Any]) {
    self.track(event, properties: properties)
  }
}
