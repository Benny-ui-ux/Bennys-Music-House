//MediaControlView
import SwiftUI

struct MediaControlView: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager

    var body: some View {
        VStack {
            if let currentTrack = audioPlayerManager.currentTrack {
                Text(currentTrack.title)
                    .font(.custom("Menlo", size: 16))
                    .padding(.top)

                Text(currentTrack.artist)
                    .font(.custom("Menlo", size: 12))
                    .padding(.bottom)

                if audioPlayerManager.trackDuration > 0 {
                    Slider(value: $audioPlayerManager.currentPlaybackPosition, in: 0...audioPlayerManager.trackDuration, onEditingChanged: { _ in
                        audioPlayerManager.seek(to: audioPlayerManager.currentPlaybackPosition)
                    })
                } else {
                    Text("Loading... Please Wait...")
                        .font(.custom("Menlo", size: 16))
                }

                HStack {
                    Button(action: {
                        audioPlayerManager.playPreviousTrack()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.custom("Menlo", size: 28))
                    }

                    Spacer()

                    Button(action: {
                        if audioPlayerManager.isPlaying {
                            audioPlayerManager.pauseAudio()
                        } else {
                            audioPlayerManager.playAudio(from: currentTrack)
                        }
                    }) {
                        Image(systemName: audioPlayerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.custom("Menlo", size: 32))
                    }

                    Spacer()

                    Button(action: {
                        audioPlayerManager.playNextTrack()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.custom("Menlo", size: 28))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

