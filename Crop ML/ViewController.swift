//  Crop ML
//  Created by Harshavoleti on 16.04.23.

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        label.font = label.font.withSize(17)
        return label
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCaptureSession()
        view.addSubview(label)
        setupLabel()
        
        // Add a button to select an image from the gallery
        let galleryButton = UIButton(type: .system)
        galleryButton.setTitle("Select Image", for: .normal)
        galleryButton.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        view.addSubview(galleryButton)
        setupGalleryButton()
        
        view.addSubview(imageView)
        setupImageView()
    }
    
    func setupCaptureSession() {
        // Your existing code for setting up the capture session
        // ...
    }
    
    @objc func selectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
            // Perform classification on the selected image
            classifyImage(image)
        }
    }
    
    func classifyImage(_ image: UIImage) {
        guard let model = try? VNCoreMLModel(for: TomatoLeafDiseaseClassifier().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
            guard let firstResult = results.first else { return }
            
            let className = firstResult.identifier
            let confidence = String(format: "%.02f%", firstResult.confidence * 100)
            
            DispatchQueue.main.async {
                self.label.text = "\(className) \(confidence)"
            }
        }
        
        guard let ciImage = CIImage(image: image) else { return }
        let imageHandler = VNImageRequestHandler(ciImage: ciImage)
        
        DispatchQueue.global(qos: .userInteractive).async {
            try? imageHandler.perform([request])
        }
    }

    func setupLabel() {
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -200).isActive = true
    }
    
    func setupGalleryButton() {
        let button = view.subviews.compactMap { $0 as? UIButton }.last
        button?.translatesAutoresizingMaskIntoConstraints = false
        button?.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button?.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -20).isActive = true
    }
    
    func setupImageView() {
        imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -20).isActive = true
    }
}

extension UIImage {
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        
        guard let buffer = pixelBuffer, status == kCVReturnSuccess else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: CGFloat(height))
        context?.scaleBy(x: 1, y: -1)
        
        UIGraphicsPushContext(context!)
        draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
