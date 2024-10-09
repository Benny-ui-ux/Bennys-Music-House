//UploadView
import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseDatabase

struct UploadView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var title = ""
    @State private var artist = ""
    @State private var audioURL: URL? = nil
    @State private var image: UIImage? = nil
    @State private var isUploading = false
    @State private var showingDocumentPicker = false
    @State private var showingImagePicker = false

    var body: some View {
        VStack {
            TextField("Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Artist", text: $artist)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Select Audio File") {
                showingDocumentPicker.toggle()
            }
            .padding()
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(selectedFile: $audioURL)
            }

            Button("Select Album Art") {
                showingImagePicker.toggle()
            }
            .padding()
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $image)
            }

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .padding()
            }

            Button(action: {
                if let audioURL = audioURL, let image = image {
                    uploadTrack(audioURL: audioURL, title: title, artist: artist, image: image)
                }
            }) {
                Text(isUploading ? "Uploading..." : "Upload")
            }
            .disabled(isUploading || audioURL == nil || image == nil)
            .padding()
        }
        .navigationTitle("Upload Track")
    }

    func uploadTrack(audioURL: URL, title: String, artist: String, image: UIImage) {
        isUploading = true
        let sanitizedFileName = audioURL.lastPathComponent.replacingOccurrences(of: " ", with: "_")

        // Upload Audio
        let audioStorageRef = Storage.storage().reference().child("tracks/\(sanitizedFileName)")
        let uploadTask = audioStorageRef.putFile(from: audioURL, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading audio file: \(error.localizedDescription)")
                isUploading = false
                return
            }
            audioStorageRef.downloadURL { audioURL, error in
                if let error = error {
                    print("Error getting audio download URL: \(error.localizedDescription)")
                    isUploading = false
                    return
                }
                guard let audioURL = audioURL else { return }

                // Upload Image
                let imageFileName = "\(UUID().uuidString).jpg"
                let imageStorageRef = Storage.storage().reference().child("album_art/\(imageFileName)")
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    imageStorageRef.putData(imageData, metadata: nil) { metadata, error in
                        if let error = error {
                            print("Error uploading image: \(error.localizedDescription)")
                            isUploading = false
                            return
                        }
                        imageStorageRef.downloadURL { imageURL, error in
                            if let error = error {
                                print("Error getting image download URL: \(error.localizedDescription)")
                                isUploading = false
                                return
                            }
                            guard let imageURL = imageURL else { return }
                            saveTrackMetadata(title: title, artist: artist, audioURL: audioURL.absoluteString, imageURL: imageURL.absoluteString)
                        }
                    }
                } else {
                    print("Error converting image to JPEG")
                    isUploading = false
                }
            }
        }
    }

    func saveTrackMetadata(title: String, artist: String, audioURL: String, imageURL: String) {
        let db = Firestore.firestore()
        let trackData: [String: Any] = [
            "title": title,
            "artist": artist,
            "audioURL": audioURL,
            "imageURL": imageURL
        ]
        db.collection("tracks").addDocument(data: trackData) { error in
            if let error = error {
                print("Error saving track metadata: \(error.localizedDescription)")
            } else {
                print("Track metadata saved successfully!")
                isUploading = false
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

