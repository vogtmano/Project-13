//
//  ViewController.swift
//  Project13.2
//
//  Created by Maks Vogtman on 10/11/2022.
//

import CoreImage
import UIKit

enum ProjectFilter: String, CaseIterable {
    case CIBumpDistortion
    case CIGaussianBlur
    case CIPixellate
    case CISepiaTone
    case CITwirlDistortion
    case CIUnsharpMask
    case CIVignette
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var intensity: UISlider!
    @IBOutlet var radius: UISlider!
    @IBOutlet var scale: UISlider!
    @IBOutlet var changeFilterButton: UIButton!
    
    var currentImage: UIImage!
    var context: CIContext!
    var currentFilter: CIFilter!
    

    override func viewDidLoad() {
        super.viewDidLoad()
    
        title = "Instafilter"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importPicture))
        
        context = CIContext()
        currentFilter = CIFilter(name: "CISepiaTone")
    }
    
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        currentImage = image
        
        // Setting currentImage as the input image for the currentFilter.
        let beginImage = CIImage(image: currentImage)
        
        imageView.alpha = 0
        UIView.animate(withDuration: 2, delay: 0, options: [], animations: {
            self.imageView.alpha = 1
        })
        
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }

    
    @IBAction func changeFilter(_ sender: UIButton) {
        let ac = UIAlertController(title: "Choose Filter", message: nil, preferredStyle: .actionSheet)
        
        ProjectFilter.allCases.forEach { filter in
            ac.addAction(UIAlertAction(title: filter.rawValue, style: .default, handler: setFilter))
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = ac.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        
        present(ac, animated: true)
    }
    
    
    @MainActor
    @objc func setFilter(action: UIAlertAction) {
        guard currentImage != nil, let actionTitle = action.title else { return }
        
        // Creating new CIFilter, using action's title (action that was tapped is the only function's parameter).
        currentFilter = CIFilter(name: actionTitle)
        
        changeFilterButton.setTitle(actionTitle, for: .normal)
        
        let beginImage = CIImage(image: currentImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        imageView.alpha = 0
        UIView.animate(withDuration: 2, delay: 0, options: [], animations: {
            self.imageView.alpha = 1
        })
        
        applyProcessing()
    }
    
    
    @IBAction func save(_ sender: Any) {
        guard let image = imageView.image else {
            let ac = UIAlertController(title: "Error", message: "There is no image.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(ac, animated: true)
            return 
        }
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_: didFinishSavingWithError: contextInfo: )), nil)
    }
    
    
    @IBAction func intensityChanged(_ sender: Any) {
        applyProcessing()
    }
    
    
    @IBAction func radiusChanged(_ sender: Any) {
        applyProcessing()
    }
    
    
    @IBAction func scaleChanged(_ sender: Any) {
        applyProcessing()
    }
    
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(intensity.value, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(radius.value * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(scale.value * 10, forKey: kCIInputScaleKey) }
        if inputKeys.contains(kCIInputCenterKey) { currentFilter.setValue(CIVector(x: currentImage.size.width / 2, y: currentImage.size.height / 2), forKey: kCIInputCenterKey) }
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            let processedImage = UIImage(cgImage: cgImage)
            imageView.image = processedImage
        }
    }
    
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered photo has been saved to the library.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
}

