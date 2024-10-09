//ContentView
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager

    var body: some View {
        NavigationView {
            TabView {
                TracksView()
                    .tabItem {
                        Label("Tracks", systemImage: "music.note.list")
                        
                    }
                

                MediaControlView()
                    .tabItem {
                        Label("Now Playing", systemImage: "play.fill")
                    }

                VStack {
                    Text("Welcome to Bennys Music House")
                        .font(.custom("Menlo", size: 16))
                        .padding()
                    
                    
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("Sign Out")
                    }
                    .padding()
                }
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            }
        }
    }
}

