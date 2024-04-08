// ContentView.swift
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var isShowingImagePicker = false
    @State private var image: UIImage?
    @State private var showSaveConfirmation = false
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue.opacity(0.3)) // 画像の背景を水色に設定
            } else {
                // 画像がない場合はデフォルトのビューを表示
                Text("撮影した写真がここに表示されます")
                    .foregroundColor(.gray)
                    .padding()
                    .background(Color.white) // テキストの背景を白に設定
            }
            
            Button(action: {
                isShowingImagePicker = true
            }) {
                Text("写真を撮る")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.pink, Color.blue]), startPoint: .leading, endPoint: .trailing)) // グラデーション背景
                    .cornerRadius(15)
                    .shadow(radius: 10)
            }
            .padding()
            .sheet(isPresented: $isShowingImagePicker) {
                CustomImagePicker(isPresented: $isShowingImagePicker, selectedImage: $image, sourceType: .camera) { image in
                    self.image = image
                    self.showSaveConfirmation = true
                }
            }
        }
        .alert(isPresented: $showSaveConfirmation) {
            Alert(
                title: Text("写真を保存しますか？"),
                primaryButton: .default(Text("保存")) {
                    if let imageToSave = image {
                        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .background(Color.white) // アプリ全体の背景を白に設定
    }
}

struct CustomImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CustomImagePicker
        var onImagePicked: (UIImage) -> Void
        
        init(_ parent: CustomImagePicker, onImagePicked: @escaping (UIImage) -> Void) {
            self.parent = parent
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                // 撮影した写真をカメラロールに保存
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}
