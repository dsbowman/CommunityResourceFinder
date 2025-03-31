//
//  RemoteImageView.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI
import FirebaseStorage

final class ImageLoader: ObservableObject {
    @Published var image: Image? = nil
    
    func load(fromURLString urlString: String) {
        NetworkManager.shared.downloadImage(fromURLString: urlString) { uiImage in
            guard let uiImage = uiImage else { return }
            DispatchQueue.main.async {
                self.image = Image(uiImage: uiImage)
            }
        }
    }
}

final class FirebaseImageLoader: ObservableObject {
    @Published var image: Image? = nil
    @Published var isLoading = false
    
    func load(fromPath path: String) {
        isLoading = true
        
        Task {
            do {
                let uiImage = try await FirebaseImageService.shared.loadImage(from: path)
                await MainActor.run {
                    self.image = Image(uiImage: uiImage)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Failed to load image: \(error.localizedDescription)")
                }
            }
        }
    }
}


struct RemoteImage: View {
    var image: Image?

    var body: some View {
        image?.resizable() ?? Image("Logo").resizable()
    }
}


struct ResourceRemoteImage: View {
    @StateObject var imageLoader = ImageLoader()
    let urlString: String
    
    var body: some View {
        RemoteImage(image: imageLoader.image)
            .onAppear {
                imageLoader.load(fromURLString: urlString)
            }
        
    }
}


struct FirebaseRemoteImage: View {
    @StateObject var imageLoader = FirebaseImageLoader()
    let path: String
    
    var body: some View {
        ZStack {
            if imageLoader.isLoading {
                ProgressView()
            } else {
                RemoteImage(image: imageLoader.image)
            }
        }
        .onAppear {
            imageLoader.load(fromPath: path)
        }
    }
}
