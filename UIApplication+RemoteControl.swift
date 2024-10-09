//UIApplication+RemoteControl
import UIKit

extension UIApplication {
    private static var remoteControlManager: RemoteControlManager?

    static func setRemoteControlManager(_ manager: RemoteControlManager) {
        remoteControlManager = manager
        shared.beginReceivingRemoteControlEvents()
    }

    static func handleRemoteControlEvent(_ event: UIEvent?) {
        remoteControlManager?.handleRemoteControlEvent(event)
    }
}

