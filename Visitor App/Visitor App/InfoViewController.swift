//
//  InfoViewController.swift
//  Visitor App
//
//  Created by Gill, Nathan on 28/11/2023.
//

import UIKit
import MapKit

class InfoViewController: UIViewController {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var txtInfo: UITextView!
    @IBOutlet weak var lblRecnum: UILabel!
    @IBOutlet var imageViews: [UIImageView]!
    @IBOutlet weak var lblNoLoc: UILabel!
    
    var recnum: String?
    var plant: PlantData?
    
    var imgData:[String] = []
    var images:[UIImage] = []
    
    //MARK: Display stuff
    
    /**
     Gets however many image file names are stored in imgData, waits to ensure they have been fetched
    */
    func imageHandle(){
        for i in 0..<imgData.count{
            ViewController.getImgThumbnail(imgData[i], "ness_images", self)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.displayImages()
        }
    }
    
    /**
     Displays however many images are needed, up to 4, any further are not displayed and if less,
     displays the remainder as placeholder images instead
    */
    func displayImages(){
        for i in 0..<images.count{
            imageViews[i].image = images[i]
        }
        for i in images.count..<imageViews.count{
            imageViews[i].image = UIImage(named: "no-image")
        }
    }
    
    /**
     Shows the map displaying the location of the plant if available
    */
    func displayMap(){
        if let lat = Double((plant?.latitude)!), let lon = Double((plant?.longitude)!){
            map.isHidden = false
            let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let annotation = MKPointAnnotation()
            let span = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            let region = MKCoordinateRegion(center: location, span: span)
            self.map.setRegion(region, animated: true)
            annotation.coordinate = location
            annotation.title = recnum
            self.map.addAnnotation(annotation)
            map.setCenter(location, animated: false)
        }
        else {
            lblNoLoc.isHidden = false
        }
    }
    
    /**
     Displays further information about the plant
    */
    func displayText(){
        let comName = plant!.vernacular_name!.isEmpty ? "no recorded common name" : plant!.vernacular_name
        let genus = plant!.genus!.isEmpty ? "no recorded genus" : plant!.genus
        let family = plant!.family!.isEmpty ? "no recorded family" : plant!.family
        let species = plant!.family!.isEmpty ? "no recorded species" : plant!.family
        let cultivarName = plant!.family!.isEmpty ? "no recorded cultivar name" : plant!.family
        txtInfo.text = """
                Genus: \(genus!)
                Family: \(family!)
                Species: \(species!)
                Common name: \(comName!)
                Cultivar name: \(cultivarName!)
                """
    }
    
    /**
     Init setup to be called in viewDidAppear()
    */
    func handleInitLoad(){
        images = []
        imageHandle()
        displayMap()
        displayText()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setu sp after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        handleInitLoad()
    }
}
 
