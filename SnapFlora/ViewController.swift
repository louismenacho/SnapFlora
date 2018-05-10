//
//  ViewController.swift
//  WhatFlower
//
//  Created by Louis Menacho on 3/30/18.
//  Copyright © 2018 Louis Menacho. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var albumButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var flowerDescription: UILabel!
    
    
    
    let imagePicker = UIImagePickerController()
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
    }
    
    // MARK: - Image Processing

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let userPickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else { fatalError("Error at userPickedImage") }
        
        guard let ciimage = CIImage(image: userPickedImage) else { fatalError("Error at ciimage") }
        
        imageView.image = userPickedImage
        
        imagePicker.dismiss(animated: true, completion: nil)
        
        detect(flowerImage: ciimage)
    }
    
    func detect(flowerImage: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else { fatalError("") }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let classification = request.results?.first as? VNClassificationObservation else {fatalError("Could not classify image")}
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    
    }
    
    @IBAction func albumTapped(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    // MARK: - Networking
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        
        Alamofire.request(wikipediaURL, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                let flowerJSON = JSON(response.result.value!)
                let pageid = "\(flowerJSON["query"]["pageids"][0])"
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.flowerDescription.text = flowerDescription
                self.flowerDescription.textAlignment = .left
                print(response)
            }
        }
    }
    
}

