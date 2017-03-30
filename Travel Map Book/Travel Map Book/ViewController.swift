//
//  ViewController.swift
//  Travel Map Book
//
//  Created by Florian Jud on 28.03.17.
//  Copyright © 2017 Florian Jud. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var chosenLatitude : Double = 0
    var chosenLongitude : Double = 0
    
    var transmittedTitle = ""
    var transmittedSubtitle = ""
    var transmittedLatitude : Double = 0
    var transmittedLongitude : Double = 0
    
    //Location recognition
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapView.delegate = self
        //Location recognition
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        //UI long press pan gesture recognizer
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.chooseLocation(gestureRecognizer:)))
        recognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(recognizer)
        
        
        //If there is a transmitted value add the annotation to the map
        if transmittedTitle != ""{
            let annotation = MKPointAnnotation()
            let coordinate = CLLocationCoordinate2D(latitude: self.transmittedLatitude, longitude: self.transmittedLongitude)
            annotation.coordinate = coordinate
            annotation.title = self.transmittedTitle
            annotation.subtitle = self.transmittedSubtitle
            self.mapView.addAnnotation(annotation)
            
            self.nameText.text = self.transmittedTitle
            self.commentText.text = self.transmittedSubtitle
        }
        
        
    }
    
    //Location recognition
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        self.mapView.setRegion(region, animated: true)
    }

    //UI long press pan gesture recognizer
    func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.began{
            //Assign gesture on the map and convert to coordinates
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let chosenCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            //Make the chose global available
            self.chosenLatitude = chosenCoordinates.latitude
            self.chosenLongitude = chosenCoordinates.longitude

            //Display a needle on the map with a title and subtitle
            let annotation = MKPointAnnotation()
            annotation.coordinate = chosenCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
            
        }
    }
    
    //Save location to coredata
    @IBAction func saveButtonClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "Locations", into: context)
        newLocation.setValue(nameText.text, forKey: "title")
        newLocation.setValue(commentText.text, forKey: "subtitle")
        newLocation.setValue(self.chosenLatitude, forKey: "latitude")
        newLocation.setValue(self.chosenLongitude, forKey: "longitude")
        
        do{
            try context.save()
            print("save")
        }catch{
            print("error")
        }
        
        //When save successfully then give a notification a go back to firstVC, there is a observed which will fetch the data again and reload the viewTable
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newLocationCreateed"), object: nil)
        _ = self.navigationController?.popViewController(animated: true)
        
    }
    
    //a. We will customize our annotation, with a navigation button at the pin
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
     
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.pinTintColor = UIColor.red
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    //b. What will happen when a users clicks on the button
    // --> Add a navigation
    var requestCLLocation = CLLocation()
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if transmittedLatitude != 0 {
            if transmittedLongitude != 0{
                self.requestCLLocation = CLLocation(latitude: transmittedLatitude, longitude: transmittedLongitude)
            }
        }
        
        CLGeocoder().reverseGeocodeLocation(requestCLLocation){
            (placemarks, error) in
            
            if let placemark = placemarks {
                if placemark.count > 0{
                    let newPlaceMark = MKPlacemark(placemark: placemark[0])
                    let item = MKMapItem(placemark: newPlaceMark)
                    item.name = self.transmittedTitle
                    
                    let launchOptions = [ MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving ]
                    item.openInMaps(launchOptions: launchOptions)
                }
            }
        }
    }
    
    
}

