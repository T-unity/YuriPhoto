//import SwiftUI
//
//struct ImageDisplayView: View {
//    @Binding var image: UIImage?
//    @Binding var isImageSaved: Bool
//    @Binding var isShowingImagePicker: Bool
//    
//    var body: some View {
//        if let image = image {
//            Image(uiImage: image)
//                .resizable()
//                .scaledToFit()
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .background(Color.blue.opacity(0.3))
//            
//            if !isImageSaved {
//                Button("ダウンロード") {
//                    saveImage()
//                }
//                .buttonStyle()
//            } else {
//                Button("撮影を続ける") {
//                    isImageSaved = false
//                    self.image = nil
//                    isShowingImagePicker = true  // カメラを再度起動する
//                }
//                .buttonStyle()
//            }
//        } else {
//            Button("写真を撮る") {
//                isShowingImagePicker = true
//            }
//            .buttonStyle()
//        }
//    }
//    
//    private func saveImage() {
//        if let imageToSave = image {
//            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
//            isImageSaved = true
//        }
//    }
//}
