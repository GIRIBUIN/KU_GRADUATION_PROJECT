import Foundation
#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

final class AppleWidgetBridge: NSObject, FlutterPlugin {
    private static var channel: FlutterMethodChannel?
    private static var pending: String?

    static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        let channel = FlutterMethodChannel(name: "ku.todo/apple-widgets", binaryMessenger: messenger)
        Self.channel = channel
        registrar.addMethodCallDelegate(AppleWidgetBridge(), channel: channel)
    }

    static func open(_ url: URL) -> Bool {
        guard url.scheme == "kutodo" else { return false }
        pending = url.absoluteString
        channel?.invokeMethod("widgetLink", arguments: url.absoluteString)
        return true
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "prepareDatabase":
                guard let args = call.arguments as? [String: Any], let source = args["sourcePath"] as? String else {
                    result(FlutterError(code: "arguments", message: "DB 경로가 필요합니다.", details: nil)); return
                }
                result(try KuWidgetStore.prepareDatabase(source: source))
            case "initialLink":
                result(Self.pending); Self.pending = nil
            case "reload":
                KuWidgetStore.changed(); result(nil)
            case "consumeChanges":
                let changed = KuWidgetStore.defaults.bool(forKey: "widget_refresh_required")
                KuWidgetStore.defaults.removeObject(forKey: "widget_refresh_required")
                result(changed)
            default: result(FlutterMethodNotImplemented)
            }
        } catch {
            result(FlutterError(code: "apple_widgets", message: error.localizedDescription, details: nil))
        }
    }
}
