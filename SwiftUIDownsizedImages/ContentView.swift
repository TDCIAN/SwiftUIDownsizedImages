//
//  ContentView.swift
//  SwiftUIDownsizedImages
//
//  Created by 김정민 on 3/3/25.
//

import SwiftUI

struct ContentView: View {
    
    let images: [UIImage] = [
        ._4Point4MB,
        ._6Point6MB,
        ._8_MB
    ]
    
    var body: some View {
        NavigationStack {
            List {
                VStack {
//                    Text("Original Images")
//                    
//                    HStack {
//                        ForEach(self.images, id: \.self) { image in
//                            Image(uiImage: image)
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                                .frame(width: 100, height: 150)
//                                .clipShape(.rect(cornerRadius: 10))
//                        }
//                    }
                    
                    Text("Downsized Images")
                    
                    HStack {
                        ForEach(self.images, id: \.self) { image in
                            /// You can specify this downsizing value as per your own requirements
                            let size = CGSize(width: 150, height: 150)
                            DownsizedImageView(image: image, size: size) { image in
                                GeometryReader { proxy in
                                    let size = proxy.size
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: size.width, height: size.height)
                                        .clipShape(.rect(cornerRadius: 10))
                                }
                                .frame(height: 150)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Downsized Image View")
        }
    }
}

#Preview {
    ContentView()
}

struct DownsizedImageView<Content: View>: View {
    var image: UIImage?
    var size: CGSize
    /// Just like how AsyncImage works
    @ViewBuilder var content: (Image) -> Content
    /// View Properties
    @State private var downsizedImageView: Image?
    
    var body: some View {
        ZStack {
            if let downsizedImageView {
                self.content(downsizedImageView)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            guard self.downsizedImageView == nil else { return }
            self.createDownsizedImage(self.image)
        }
        .onChange(of: self.image) { oldValue, newValue in
            guard oldValue != newValue else { return }
            /// Dynamic Image Changes
            self.createDownsizedImage(newValue)
        }
    }
    
    /// Creating Downsized Image
    private func createDownsizedImage(_ image: UIImage?) {
        guard let image else { return }
        let aspectSize = image.size.aspectFit(self.size)
        /// Creating a smaller version of the image in a separate thread so that it will affect the main thread while it's generating
        Task.detached(priority: .high) {
            let renderer = UIGraphicsImageRenderer(size: aspectSize)
            let resizedImage = renderer.image { context in
                image.draw(in: .init(origin: .zero, size: aspectSize))
            }
            
            /// Updating UI on Main Thread
            await MainActor.run {
                self.downsizedImageView = Image(uiImage: resizedImage)
            }
        }
    }
}

extension CGSize {
    /// This function will return a new size that fits the given size in an aspect ratio
    func aspectFit(_ to: CGSize) -> CGSize {
        let scaleX = to.width / self.width
        let scaleY = to.height / self.height
        
        let aspectRatio = min(scaleX, scaleY)
        return .init(width: aspectRatio * width, height: aspectRatio * height)
    }
}
