//AudioPlayerManager
import Foundation
import AVFoundation
import MediaPlayer

class AudioPlayerManager: ObservableObject {
    @Published var currentTrack: Track?
    @Published var currentPlaybackPosition: Double = 0.0
    @Published var isPlaying: Bool = false
    @Published var tracks: [Track] = []

    private var audioPlayer: AVPlayer?
    private var timeObserver: Any?
    private var currentIndex: Int? {
        guard let currentTrack = currentTrack else { return nil }
        return tracks.firstIndex(where: { $0.id == currentTrack.id })
    }

    var trackDuration: Double {
        return audioPlayer?.currentItem?.duration.seconds ?? 0
    }

    static let shared = AudioPlayerManager()

    private init() {
        setupRemoteCommandCenter()
    }

    func playAudio(from track: Track) {
        guard let url = URL(string: track.audioURL) else {
            print("Invalid URL string: \(track.audioURL)")
            return
        }

        // Check if the new track is different from the current one
        if currentTrack?.id != track.id {
            // Reset the playback position for the new track
            currentPlaybackPosition = 0.0
            audioPlayer?.pause() // Pause the previous track
            audioPlayer = nil // Clear the previous audio player instance
        }

        let playerItem = AVPlayerItem(url: url)
        audioPlayer = AVPlayer(playerItem: playerItem)

        // Seek to the correct position: start from 0 for new tracks, or resume for the same track
        let startTime = CMTime(seconds: currentTrack?.id == track.id ? currentPlaybackPosition : 0, preferredTimescale: 1)
        audioPlayer?.seek(to: startTime)

        audioPlayer?.play()
        isPlaying = true
        currentTrack = track
        startUpdatingPlaybackPosition()
        updateNowPlayingInfo()
    }



    func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        if let currentTime = audioPlayer?.currentTime().seconds {
            currentPlaybackPosition = currentTime
        }
        updateNowPlayingInfo()
    }

    func seek(to position: Double) {
        let time = CMTime(seconds: position, preferredTimescale: 1)
        audioPlayer?.seek(to: time)
        currentPlaybackPosition = position
        updateNowPlayingInfo()
    }

    func playNextTrack() {
        guard let currentIndex = currentIndex, currentIndex < tracks.count - 1 else {
            print("No next track available")
            return
        }
        let nextTrack = tracks[currentIndex + 1]
        playAudio(from: nextTrack)
    }

    func playPreviousTrack() {
        guard let currentIndex = currentIndex, currentIndex > 0 else {
            print("No previous track available")
            return
        }
        let previousTrack = tracks[currentIndex - 1]
        playAudio(from: previousTrack)
    }

    func resumePlayback() {
        if !isPlaying {
            audioPlayer?.play()
            isPlaying = true
            updateNowPlayingInfo()
        }
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] event in
            if let self = self {
                if self.isPlaying {
                    self.resumePlayback()
                } else {
                    if let track = self.currentTrack {
                        self.playAudio(from: track)
                    }
                }
                return .success
            }
            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pauseAudio()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.playNextTrack()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.playPreviousTrack()
            return .success
        }
    }

    private func setupNowPlayingInfo() {
        guard let track = currentTrack else { return }

        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentPlaybackPosition
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = trackDuration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        if let imageURL = URL(string: track.imageURL) {
            let task = URLSession.shared.dataTask(with: imageURL) { [weak self] data, response, error in
                guard let data = data, error == nil, let image = UIImage(data: data) else {
                    return
                }

                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in
                    return image
                }

                DispatchQueue.main.async {
                    var nowPlayingInfoWithArtwork = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                    nowPlayingInfoWithArtwork[MPMediaItemPropertyArtwork] = artwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfoWithArtwork
                }
            }
            task.resume()
        }
    }

    private func startUpdatingPlaybackPosition() {
        timeObserver = audioPlayer?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] time in
            self?.currentPlaybackPosition = time.seconds
            self?.updateNowPlayingInfo()
        }
    }

    private func updateNowPlayingInfo() {
        setupNowPlayingInfo()
    }

    deinit {
        if let timeObserver = timeObserver {
            audioPlayer?.removeTimeObserver(timeObserver)
        }
    }
}

