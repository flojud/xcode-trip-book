//
//  firstViewController.swift
//  Travel Map Book
//
//  Created by Florian Jud on 30.03.17.
//  Copyright © 2017 Florian Jud. All rights reserved.
//

import UIKit
import CoreData

class firstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var tableView: UITableView!
    
    var titleArray = [String]()
    var subTitleArray = [String]()
    var latitudeArray = [Double]()
    var longitudeArray = [Double]()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Setup tableView
        tableView.delegate = self
        tableView.dataSource = self
        
        //Fetch the entires from core data base
        fetchData()
        
    }

    //define the numver of rows of the tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    
    //fill the content of the tableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //define cell
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
        
    }
    
    //Add button clicked
    @IBAction func addButtonClicked(_ sender: Any) {
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    //Fetch the entires from the core data base
    func fetchData(){
        //Initialiaze the appDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        //Form the fetch request
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
        //Request it
        request.returnsObjectsAsFaults = false
        do{
            let results = try context.fetch(request)
            
            //Check the result from core data and assign it to the variables
            if results.count > 0 {
                
                //First clear arrays to ensure no conflicts
                self.titleArray.removeAll(keepingCapacity: false)
                self.subTitleArray.removeAll(keepingCapacity: false)
                self.latitudeArray.removeAll(keepingCapacity: false)
                self.longitudeArray.removeAll(keepingCapacity: false)
                
                
                for result in results as! [NSManagedObject]{
                    if let title = result.value(forKey: "title") as? String{
                        self.titleArray.append(title)
                    }
                    
                    if let subtitle = result.value(forKey: "subtitle") as? String{
                        self.subTitleArray.append(subtitle)
                    }
                    
                    if let latitude = result.value(forKey: "latitude") as? Double{
                        self.latitudeArray.append(latitude)
                    }
                    
                    if let longitude = result.value(forKey: "longitude") as? Double{
                        self.longitudeArray.append(longitude)
                    }
                    self.tableView.reloadData()
                }
            }
        }catch{
            print("An error ocoured")
        }
        
    }
  
    //1. Variables for transmission to VC
    var choosenTitle = ""
    var choosenSubtitle = ""
    var choosenLatitude : Double = 0
    var choosenLongitude : Double = 0
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        choosenTitle = titleArray[indexPath.row]
        choosenSubtitle = subTitleArray[indexPath.row]
        choosenLatitude = latitudeArray[indexPath.row]
        choosenLongitude = longitudeArray[indexPath.row]
        
        //3. Perform Segue toMapVC
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    //2. Prepare Segue to toMapVC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC"{
            let destinationVC =  segue.destination as! ViewController
            destinationVC.transmittedTitle = choosenTitle
            destinationVC.transmittedSubtitle = choosenSubtitle
            destinationVC.transmittedLatitude = choosenLatitude
            destinationVC.transmittedLongitude = choosenLongitude
        }
    }
    
    //This the observer which will fetch data again and relaoad the viewTable, this will happen, when a new annotation is saved to core data
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(firstViewController.fetchData), name: NSNotification.Name(rawValue: "newLocationCreateed"), object: nil)
    }
}
