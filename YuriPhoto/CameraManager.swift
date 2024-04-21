//import SwiftUI
//import AVFoundation
//
//class CameraManager: NSObject {
//    var session: AVCaptureSession
//    var photoOutput: AVCapturePhotoOutput
//    var previewLayer: AVCaptureVideoPreviewLayer?
//    
//    override init() {
//        self.session = AVCaptureSession()
//        self.photoOutput = AVCapturePhotoOutput()
//        super.init()
//        self.setupSession()
//    }
//    
//    private func setupSession() {
//        session.beginConfiguration()
//        
//        guard let backCamera = AVCaptureDevice.default(for: .video),
//              let input = try? AVCaptureDeviceInput(device: backCamera) else {
//            fatalError("Unable to access back camera")
//        }
//        
//        if session.canAddInput(input) {
//            session.addInput(input)
//        } else {
//            fatalError("Cannot add input to the session")
//        }
//        
//        if session.canAddOutput(photoOutput) {
//            session.addOutput(photoOutput)
//        } else {
//            fatalError("Cannot add output to the session")
//        }
//        
//        session.commitConfiguration()
//        setupPreviewLayer()
//    }
//    
//    private func setupPreviewLayer() {
//        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
//        self.previewLayer?.videoGravity = .resizeAspectFill
//    }
//    
//    func startSession() {
//        if !session.isRunning {
//            session.startRunning()
//        }
//    }
//    
//    func stopSession() {
//        if session.isRunning {
//            session.stopRunning()
//        }
//    }
//    
//    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
//        let settings = AVCapturePhotoSettings()
//        if session.isRunning {
//            photoOutput.capturePhoto(with: settings, delegate: delegate)
//        } else {
//            print("Session is not running")
//        }
//    }
//}
//
//extension CameraManager: AVCapturePhotoCaptureDelegate {
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
//        if let error = error {
//            print("Error capturing photo: \(error.localizedDescription)")
//        } else {
//            print("Photo captured successfully")
//        }
//    }
//}
