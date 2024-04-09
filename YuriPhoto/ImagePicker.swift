//import SwiftUI
//import UIKit
//
//struct ImagePicker: UIViewControllerRepresentable {
//    @Binding var isPresented: Bool
//    @Binding var selectedImage: UIImage?
//    var sourceType: UIImagePickerController.SourceType
//    var onImagePicked: (UIImage?) -> Void
//    
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        picker.sourceType = sourceType
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self, onImagePicked: onImagePicked)
//    }
//    
//    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//        var parent: ImagePicker
//        var onImagePicked: (UIImage?) -> Void
//        
//        init(_ parent: ImagePicker, onImagePicked: @escaping (UIImage?) -> Void) {
//            self.parent = parent
//            self.onImagePicked = onImagePicked
//        }
//        
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//            let image = info[.originalImage] as? UIImage
//            self.onImagePicked(image)
//            parent.isPresented = false
//        }
//        
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            self.onImagePicked(nil)
//            parent.isPresented = false
//        }
//    }
//}
