//
//  ViewController.swift
//  WhatFlower
//
//  Created by Justin Rose on 5/19/19.
//  Copyright © 2019 Justin Rose. All rights reserved.
//

import UIKit
import Vision
import CoreML
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var wikiLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            //imageView.image = userPickedImage
            guard let ciimage = CIImage(image: userPickedImage) else { fatalError("unable to convert UIImage to CIImage") }
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else { fatalError("Loading CoreML model failed") }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let results = request.results as? [VNClassificationObservation] else { fatalError("Model failed to process image") }
            
            if let firstResult = results.first {
                let flowerName = firstResult.identifier.capitalized
                
                self.navigationItem.title = flowerName
                
                self.getWikiInfo(for: flowerName)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func getWikiInfo(for flowerName: String) {
        let parameters : [String : String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "piprop" : "original",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1"
        ]
        
        AF.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            
            if let wikiResponse = response.value {
                
                let wikiJSON = JSON(wikiResponse)

                self.printWikiInfo(json: wikiJSON)
            }
        }
    }
    
    func printWikiInfo(json: JSON) {
        let pageID = json["query"]["pageids"][0].stringValue
            
        //set lines to 0 and set a minimum font size in the property inspector to fit all of the text from the extract
        wikiLabel.text = json["query"]["pages"][pageID]["extract"].stringValue
        
        imageView.sd_setImage(with: URL(string: json["query"]["pages"][pageID]["original"]["source"].stringValue))
    }
}

