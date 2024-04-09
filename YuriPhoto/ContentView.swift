import SwiftUI

struct ContentView: View {
    @State private var isShowingImagePicker = false
    @State private var image: UIImage?
    @State private var isImageSaved = false
    
    var body: some View {
        VStack {
            ImageDisplayView(image: $image, isImageSaved: $isImageSaved, isShowingImagePicker: $isShowingImagePicker)
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(isPresented: $isShowingImagePicker, selectedImage: $image, sourceType: .camera) { selectedImage in
                self.image = selectedImage
                self.isImageSaved = false
            }
        }
        .background(Color.white)
    }
}
