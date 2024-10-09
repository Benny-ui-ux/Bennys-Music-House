//BennysMusicHouseApp
import SwiftUI
import Firebase
import FirebaseAuth
import AVFoundation

@main
struct BennysMusicHouseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var audioPlayerManager = AudioPlayerManager.shared

    var body: some Scene {
        WindowGroup {
            if authViewModel.isLoggedIn {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(audioPlayerManager)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    private var remoteControlManager: RemoteControlManager?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        configureAudioSession()

        remoteControlManager = RemoteControlManager(audioPlayerManager: AudioPlayerManager.shared)
        UIApplication.setRemoteControlManager(remoteControlManager!)
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        let audioPlayerManager = AudioPlayerManager.shared
        UserDefaults.standard.set(audioPlayerManager.currentPlaybackPosition, forKey: "PlaybackPosition")
        UserDefaults.standard.set(audioPlayerManager.isPlaying, forKey: "IsPlaying")
        UserDefaults.standard.set(audioPlayerManager.currentTrack?.id, forKey: "CurrentTrackID")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        let audioPlayerManager = AudioPlayerManager.shared
        let savedPosition = UserDefaults.standard.double(forKey: "PlaybackPosition")
        let wasPlaying = UserDefaults.standard.bool(forKey: "IsPlaying")
        let trackID = UserDefaults.standard.string(forKey: "CurrentTrackID")
        
        audioPlayerManager.currentPlaybackPosition = savedPosition
        
        if let trackID = trackID, let track = audioPlayerManager.tracks.first(where: { $0.id == trackID }) {
            audioPlayerManager.currentTrack = track
            audioPlayerManager.seek(to: savedPosition)
            if wasPlaying {
                audioPlayerManager.resumePlayback()
            }
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
}
