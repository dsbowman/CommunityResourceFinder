//
//  ResourceImage.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 3/30/25.
//

import SwiftUI
import FirebaseStorage

struct FirebaseImage: View {
    let path: String?
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 0
    var contentMode: ContentMode = .fit
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(width: width, height: height)
                    .cornerRadius(cornerRadius)
            } else if isLoading {
                ProgressView()
                    .frame(width: width, height: height)
            } else {
                // Default placeholder
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(width: width, height: height)
                    .foregroundColor(.gray)
            }
        }
        .task {
            if let path = path {
                await loadImage(from: path)
            }
        }
    }
    
    private func loadImage(from path: String) async {
        guard !isLoading, image == nil else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            image = try await FirebaseImageService.shared.loadImage(from: path)
        } catch {
            self.error = error
            print("Error loading image: \(error.localizedDescription)")
        }
    }
}

//#Preview {
//    FirebaseImage()
//}
