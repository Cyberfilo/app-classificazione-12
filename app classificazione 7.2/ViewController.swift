//
//  ViewController.swift
//  classificazione campioni   7.2
//
//  Created by Filippo Mattia Menghi on 06/04/24.
//
import UIKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resultLabel.text = "Choose an image to start"
    }
    
    @IBAction func pickImage(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // UIImagePickerControllerDelegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[.originalImage] as? UIImage else {
            resultLabel.text = "Could not get the image."
            return
        }
        imageView.image = image
        classifyImage(image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func classifyImage(_ image: UIImage) {
        // Assuming MyImageClassifier is your Core ML model's automatically generated class
        guard let model = try? VNCoreMLModel(for: MyImageClassifier().model) else {
            resultLabel.text = "Loading the model failed."
            return
        }
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            self?.processClassifications(for: request, error: error)
        }
        request.imageCropAndScaleOption = .centerCrop
        guard let ciImage = CIImage(image: image) else { return }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.resultLabel.text = "Image classification failed."
                }
            }
        }
    }
    
    private func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                self.resultLabel.text = "Classification failed: \(error?.localizedDescription ?? "Unknown error")"
                return
            }
            self.resultLabel.text = "Class: \(topResult.identifier), Confidence: \(topResult.confidence)"
        }
    }
}
