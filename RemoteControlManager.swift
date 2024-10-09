//RemoteControlManager
import UIKit

class RemoteControlManager {
    private weak var audioPlayerManager: AudioPlayerManager?
    
    init(audioPlayerManager: AudioPlayerManager) {
        self.audioPlayerManager = audioPlayerManager
    }
    
    func handleRemoteControlEvent(_ event: UIEvent?) {
        guard let event = event, let audioPlayerManager = audioPlayerManager else { return }
        
        switch event.subtype {
        case .remoteControlPlay:
            if !audioPlayerManager.isPlaying {
                audioPlayerManager.resumePlayback()
            }
        case .remoteControlPause:
            audioPlayerManager.pauseAudio()
        case .remoteControlNextTrack:
            audioPlayerManager.playNextTrack()
        case .remoteControlPreviousTrack:
            audioPlayerManager.playPreviousTrack()
        default:
            break
        }
    }
}

