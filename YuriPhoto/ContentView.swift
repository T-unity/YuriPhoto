import SwiftUI
import UIKit

struct ContentView: View {
    @State private var isShowingImagePicker = false
    @State private var image: UIImage?
    @State private var isImageSaved = false
    
    var body: some View {
        VStack {
            if var image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue.opacity(0.3))
                
                if !isImageSaved {
                    // 画像が保存されていない場合のみ「ダウンロード」ボタンを表示
                    Button("ダウンロード") {
                        saveImage()
                    }
                    .buttonStyle()
                } else {
                    Button("撮影を続ける") {
                        isImageSaved = false
//                        image = nil  // 画像をリセット
                        isShowingImagePicker = false
                    }
                    .buttonStyle()
                }
            } else {
                // 画像がない場合のビュー
                Button("写真を撮る") {
                    isShowingImagePicker = true
                }
                .buttonStyle()
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(isPresented: $isShowingImagePicker, selectedImage: $image, sourceType: .camera) { selectedImage in
                self.image = selectedImage
                self.isImageSaved = false  // 新しい画像が選択されたため、保存状態をリセット
            }
        }
        .background(Color.white)
    }
    
    private func saveImage() {
        if let imageToSave = image {
            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
            isImageSaved = true
        }
    }
}
