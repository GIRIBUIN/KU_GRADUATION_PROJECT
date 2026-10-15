import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions) {
    // Queue a cold-start widget link before Flutter creates its first frame.
    for context in connectionOptions.urlContexts {
      _ = AppleWidgetBridge.open(context.url)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    let remaining = URLContexts.filter { !AppleWidgetBridge.open($0.url) }
    if !remaining.isEmpty {
      super.scene(scene, openURLContexts: Set(remaining))
    }
  }
}
