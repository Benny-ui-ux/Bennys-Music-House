//TracksView
import SwiftUI
import Firebase
import FirebaseFirestore
import AVFoundation

struct Track: Identifiable {
    var id: String
    var title: String
    var artist: String
    var audioURL: String
    var imageURL: String
}

class TracksViewModel: ObservableObject {
    @Published var tracks = [Track]()
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private var db = Firestore.firestore()

    func fetchTracks() {
        isLoading = true
        db.collection("tracks").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Error fetching tracks: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.errorMessage = "No tracks found."
                    return
                }
                
                self?.tracks = documents.compactMap { document in
                    let data = document.data()
                    guard let title = data["title"] as? String,
                          let artist = data["artist"] as? String,
                          let audioURL = data["audioURL"] as? String,
                          let imageURL = data["imageURL"] as? String else { return nil }
                    return Track(id: document.documentID, title: title, artist: artist, audioURL: audioURL, imageURL: imageURL)
                }
            }
        }
    }
}

struct TracksView: View {
    @StateObject private var viewModel = TracksViewModel()
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager // Use EnvironmentObject

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading tracks...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    List(viewModel.tracks) { track in
                        TrackRow(track: track)
                    }
                }
            }
            .onAppear {
                viewModel.fetchTracks()
            }
            .navigationTitle("Tracks")
            .font(.custom("Menlo", size: 16))
        }
    }
}

struct TrackRow: View {
    let track: Track
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager

    var body: some View {
        VStack(alignment: .leading) {
            if let imageURL = URL(string: track.imageURL) {
                AsyncImage(url: imageURL) { image in
                    image.resizable()
                         .scaledToFit()
                         .frame(height: 150)
                } placeholder: {
                    ProgressView()
                }
            }
            Text(track.title)
                .font(.custom("Menlo", size: 16))
            Text(track.artist)
                .font(.custom("Menlo", size: 12))
            
            HStack {
                Button(action: {
                    if audioPlayerManager.isPlaying && audioPlayerManager.currentTrack?.id == track.id {
                        audioPlayerManager.pauseAudio()
                    } else {
                        audioPlayerManager.playAudio(from: track)
                    }
                }) {
                    Image(systemName: audioPlayerManager.isPlaying && audioPlayerManager.currentTrack?.id == track.id ? "pause.fill" : "play.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}



