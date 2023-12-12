//
//  ViewController.swift
//  Visitor App
//
//  Created by Gill, Nathan on 23/11/2023.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate{
    
    @IBOutlet weak var lblInform: UILabel!
    @IBOutlet weak var lblLoading: UILabel!
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var theTable: UITableView!
    
    //location vars
    
    var locationManager = CLLocationManager()
    var firstRun = true
    var startTrackingTheUser = false
    
    //API vars
    
    var plantBeds:BedArr?
    var plantData:PlantArr?
    var imageData:ImageArr?
    
    //formatting vars
    
    var formattedPlantData:[PlantBedDataType] = []
    var imageOnRecnum:[String:[ImageData]] = [:]
    var plantOnRecnum:[String:PlantData] = [:]
    
    //core data vars
    
    var favourited:[NSManagedObject] = []
    var cachedPlants:[NSManagedObject]=[]
    var cachedBeds:[NSManagedObject]=[]
    
    //other
    
    var currImage:UIImage?
    var selectedRecnum:String?
    
    //MARK: Location stuff
    
    /**
    Function to track the users location and display it on the map

    - parameter locations
    - parameter manager

    */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationOfUser = locations[0] //this method returns an array of locations
        //generally we always want the first one (usually there's only 1 anyway)
        
        let latitude = locationOfUser.coordinate.latitude
        let longitude = locationOfUser.coordinate.longitude
        //get the users location (latitude & longitude)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        if firstRun {
            firstRun = false
            let latDelta: CLLocationDegrees = 0.0025
            let lonDelta: CLLocationDegrees = 0.0025
            //a span defines how large an area is depicted on the map.
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            
            //a region defines a centre and a size of area covered.
            let region = MKCoordinateRegion(center: location, span: span)
            
            //make the map show that region we just defined.
            self.myMap.setRegion(region, animated: true)
            
            //we setup a timer to set our boolean to true in 5 seconds.
            _ = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(startUserTracking), userInfo: nil, repeats: false)
        }
        
        if startTrackingTheUser == true {
            //calculate the distance to the user once tracking has begun
            calculateDistance(locationOfUser)
            myMap.setCenter(location, animated: true)
        }
    }
    
    /**
     sets the startTrackingTheUser boolean class property to true
     to didUpdateLocations will cause the map to center on the user's location.
    */
    @objc func startUserTracking() {
        startTrackingTheUser = true
    }
    
    //MARK: API stuff
    
    /**
     Reloads the table
    */
    func updateTable(){
        theTable.reloadData()
    }
    
    /**
     Gets all the data related to the plants images and stores it in a variable of type ImageArr
    */
    func getImageData(){
        if let url = URL(string:"https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/ness/data.php?class=images"){
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, err) in
                guard let jsonData = data else {
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let imgList = try decoder.decode(ImageArr.self, from: jsonData)
                    self.imageData = imgList
                    DispatchQueue.main.async {
                        self.formatImageData()
                    }
                }
                catch let jsonErr {
                    print("Error decoding JSON", jsonErr)
                }
            }.resume()
        }
    }
    
    /**
     Gets the data related to a single image or thumbnail depending on the context and stores it, public and static as used within InfoViewController to avoid code redundancy 
     
     - parameter fileName: Image file name
     - parameter fileType: ness images or ness thumbnails
     - parameter VCType: Instance of the view controller that called the function to determine what to do with image
     
    */
    public static func getImgThumbnail(_ fileName: String, _ fileType: String, _ VCtype:UIViewController){
        if let url = URL(string: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/\(fileType)/\(fileName)") {
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, err) in
                guard let imgData = data else {
                    return
                }
                DispatchQueue.main.async {
                    //do different things depending on the view controller that called it
                    if let VC = VCtype as? ViewController {
                        VC.currImage = UIImage(data: imgData)
                    }
                    if let VC = VCtype as? InfoViewController {
                        VC.images.append(UIImage(data: imgData)!)
                    }
                    
                }
            }.resume()
        }
    }
    
    /**
     Gets all the data related to the beds and stores it in a variable of type BedArr
    */
    func getBedData(){
        if let url = URL(string: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/ness/data.php?class=beds") {
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, err) in
                guard let jsonData = data else {
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let bedList = try decoder.decode(BedArr.self, from: jsonData)
                    self.plantBeds = bedList
                    DispatchQueue.main.async {
                        //Once the data is available, call handle bed saving to check if there are any new entries
                        self.handleBedSaving()
                        self.updateTable()
                    }
                }
                catch let jsonErr {
                    print("Error decoding JSON", jsonErr)
                }
            }.resume()
        }
    }
    
    /**
     Gets all the data related to the plants and stores it in a variable of type PlantArr
    */
    func getPlantData(){
        if let url = URL(string: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/ness/data.php?class=plants") {
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, err) in
                guard let jsonData = data else {
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let plantList = try decoder.decode(PlantArr.self, from: jsonData)
                    self.plantData = plantList
                    DispatchQueue.main.async {
                        //Once the data is available, call handle plant saving to check if there are any new entries
                        self.handlePlantSaving()
                        self.updateTable()
                    }
                }
                catch let jsonErr {
                    print("Error decoding JSON", jsonErr)
                }
            }.resume()
        }
    }
    
    //MARK: Formatting data
    
    /**
     Formats the image data into a dictionary where the recnum is the key and all of the image data is the value
    */
    func formatImageData(){
        var temp:[ImageData]
        //loop through, if nothing is currently stored for that recnum, add it
        //if it already exists, just add the data as a value
        for i in 0..<((imageData?.images.count)!){
            if imageOnRecnum[(imageData?.images[i].recnum)!] != nil{
                temp = imageOnRecnum[(imageData?.images[i].recnum)!]!
                temp.append((imageData?.images[i])!)
                imageOnRecnum.updateValue(temp, forKey: (imageData?.images[i].recnum)!)
            }
            else {
                imageOnRecnum[(imageData?.images[i].recnum)!] = [(imageData?.images[i])!]
            }
        }
    }
    
    /**
     Formats all the plant and bed data into data structures more suitable for use, the details of how this works are
     specified within the function
    */
    func formatPlantData(){
        var bedArr:[String?] = []
        var removed = 0
        var i = 0
        
        //removes all plants that are dead or removed
        while (i != ((plantData?.plants.count)! - removed)) {
            if plantData?.plants[i].accsta != "C" {
                plantData?.plants.remove(at: i)
                removed += 1
            }
            i += 1
        }
        
        //places the bed ids into the bed_id of the custom type used to store them
        for i in 0..<(plantBeds?.beds.count)! {
            formattedPlantData.append(PlantBedDataType(bed_id: (plantBeds?.beds[i].bed_id)!, data: []))
        }
        
        ///for each plant, split the beds on the whitespaces and loop through them along with the number of beds stored in
        ///the formatted plant data and if they match, place them in the plantData array section of the custom type
        for i in 0..<(plantData?.plants.count)!{
            bedArr = (plantData?.plants[i].bed)!.components(separatedBy: .whitespaces)
            for j in 0..<bedArr.count {
                for t in 0..<formattedPlantData.count{
                    if bedArr[j]!.capitalized == (formattedPlantData[t].bed_id!).capitalized {
                        formattedPlantData[t].data.append((plantData?.plants[i])!)
                    }
                }
            }
        }
        
        //initialise dictionary for passing of information to info screen
        for i in 0..<(plantData?.plants.count)!{
            guard plantOnRecnum[(plantData?.plants[i].recnum)!] == nil else {
                return
            }
            plantOnRecnum[(plantData?.plants[i].recnum)!] = plantData?.plants[i]
        }
    }
    
    
    //MARK: Table related stuff
    
    /**
     Returns the number of sections in the table
     
     - parameter tableView: The table view
     
    */
    func numberOfSections(in tableView: UITableView) -> Int {
        return plantBeds?.beds.count ?? 0
    }
    
    /**
     Returns the title of the specified section in the table
     
     - parameter tableView: The table view
     - parameter section: The current section
     
    */
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard formattedPlantData.count != 0 else{
            return ""
        }
        return plantBeds?.beds[section].name ?? plantBeds?.beds[section].bed_id
    }
    
    /**
     Returns the number of rows in the specific section
     
     - parameter tableView: The table view
     - parameter section: The current section
     
    */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard plantData?.plants.count != nil else {
            return 0
        }
        guard formattedPlantData.count != 0 else{
            return 0
        }
        
        for i in 0..<(formattedPlantData.count){
            if formattedPlantData[i].bed_id?.capitalized == plantBeds?.beds[section].bed_id?.capitalized {
                return formattedPlantData[i].data.count
            }
        }
        return 0
    }
    
    /**
     Returns a specific cell once it has been formatted with the relevant information correctly
     
     - parameter tableView: The table view
     - parameter indexPath: the index of the current cell
     
    */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as! CustomCell
        
        guard plantData?.plants.count != nil else {
            return cell
        }
        guard formattedPlantData.count != 0 else{
            return cell
        }
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        cell.addGestureRecognizer(longPress)
        cell.backgroundColor = UIColor.systemBrown
        cell.contentView.layer.borderWidth = 0.5
        cell.contentView.layer.borderColor = UIColor.black.cgColor
        
        ///loop through all plants, check if the bed ID matches the ID of the current section, if it does, add it to the section
        for i in 0..<(formattedPlantData.count){
            if formattedPlantData[i].bed_id?.capitalized == plantBeds?.beds[indexPath.section].bed_id?.capitalized {
                cell.txtMain.text = "Species: \(formattedPlantData[i].data[indexPath.row].species ?? "no recorded species")"
                cell.txtSec.text = "Genus: \(formattedPlantData[i].data[indexPath.row].genus ?? "no recorded genus")"
                cell.recnumHdn.text = formattedPlantData[i].data[indexPath.row].recnum
                cell.imgFav.isHidden = true;
                
                for j in 0..<(favourited.count){
                    if favourited[j].value(forKeyPath: "recnum") as? String == cell.recnumHdn.text{
                        cell.imgFav.isHidden = false;
                    }
                }
                
                //half working, fix
                if imageOnRecnum[cell.recnumHdn.text!] != nil && imageOnRecnum[cell.recnumHdn.text!]?[0].img_file_name != nil {
                    ViewController.getImgThumbnail((imageOnRecnum[cell.recnumHdn.text!]?[0].img_file_name)!, "ness_thumbnails", self)
                    cell.imgPlant.image = currImage
                }
                else {
                    cell.imgPlant.image = UIImage(named: "no-image")
                }
                
                return cell
            }
        }
            
        return cell
    }
    
    /**
     Handles what to do if a cell is tapped
     
     - parameter tableView: The table view
     - parameter indexPath: The index of the current cell
     
    */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = theTable.cellForRow(at: indexPath) as! CustomCell
        selectedRecnum = cell.recnumHdn.text
        performSegue(withIdentifier: "toDetail", sender: nil)
    }
    
    /**
     In this context, handles what information needs to be passed to the info view controller
     
     - parameter segue: A storyboard segue
     - parameter sender: Sender of information
     
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail"{
            let sndVC = segue.destination as! InfoViewController
            sndVC.recnum = selectedRecnum
            sndVC.plant = plantOnRecnum[selectedRecnum!]
            
            if let img = imageOnRecnum[selectedRecnum!] {
                for i in 0..<(min(img.count, 4)){
                    sndVC.imgData.append(img[i].img_file_name!)
                }
            }
        }
    }
    
    /**
     Trailing closure function used to sort the table by the distance from the user, simply compares locations
     
     - parameter location: location for comparison
     
    */
    func calculateDistance(_ location:CLLocation){
        plantBeds!.beds.sort { (i1, i2) -> Bool in
            let location1 = CLLocation(latitude: Double(i1.latitude!)!, longitude: Double(i1.longitude!)!)
            let location2 = CLLocation(latitude: Double(i2.latitude!)!, longitude: Double(i2.longitude!)!)
            let dist1 = location.distance(from: location1)
            let dist2 = location.distance(from: location2)
            return dist1 < dist2
        }
        updateTable()
    }
    
    /**
     Handles what takes place if a cell is long pressed by the user
     
     - parameter sender: sender
     
    */
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer){
        var found = false
        if sender.state == .began{
            let loc = sender.location(in: theTable)
            
            guard let indexPath = theTable.indexPathForRow(at: loc) else {
                return
            }
            
            guard let cell = theTable.cellForRow(at: indexPath) as? CustomCell else {
                return
            }
            
            //if value is already favourited, remove it from favourites instead
            for i in 0..<favourited.count{
                if favourited[i].value(forKeyPath: "recnum") as? String == cell.recnumHdn.text!{
                    delete(cell.recnumHdn.text!)
                    found = true
                    break
                }
            }
            //if not found then save it
            if !found{
                //see func save() doc comment for how this formatting works, even if it is relatively simple
                save("Favourited", [["recnum", cell.recnumHdn.text!]])
            }
        }
    }
    
    //MARK: Core Data Stuff
    
    /**
     Fetches information from core data depending on the context of its use
     
     - parameter entitiyName: The entity from core data to be fetched
     
    */
    func fetch(_ entityName: String){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        
        do {
            switch(entityName){
            case "Favourited":
                favourited = try managedContext.fetch(fetchRequest)
            case "Plant":
                cachedPlants = try managedContext.fetch(fetchRequest)
            case "Bed":
                cachedBeds = try managedContext.fetch(fetchRequest)
            default:
                print("err with fetch num: \(entityName)")
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    /**
     Removes a favourited plant from core data
     
     - parameter recnum: The recnum of the plant to be deleted
     
    */
    func delete(_ recnum: String) {
    // Delete the object from Core Data
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        var contactToDelete:NSManagedObject?
        
        //loop through favoried and assign contactToDelete when it matches the recnum to delete
        for i in 0..<(favourited.count){
            if favourited[i].value(forKeyPath: "recnum") as? String == recnum {
                contactToDelete = favourited[i]
                // Remove the object from the array
                favourited.remove(at: i)
                break
            }
        }
        managedContext.delete(contactToDelete!)
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
        }
        updateTable()
    }
    
    /**
     Saves information about a favorited plant to core data
     
     - parameter entityToSave: The name of the entity in core data to save to
     - parameter valsToSave: The values to be saved, element 0 stores the name in core data and element 1 stores the value, 2d array of size vals * 2
     
    */
    func save(_ entityToSave: String, _ valsToSave:[[String]]){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fav = NSEntityDescription.insertNewObject(forEntityName: entityToSave, into: managedContext)
        for i in 0..<valsToSave.count{
            fav.setValue(valsToSave[i][1], forKeyPath: valsToSave[i][0])
        }
        
        do {
            try managedContext.save()
            //append in the case of favourites, this is handled elsewhere for the other 2
            if entityToSave == "Favourited"{
                favourited.append(fav)
            }
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        updateTable()
    }
    
    /**
     Checks if an entity already exists in Core Data based on its recnum, used in plant saving to ensure entries are not stored more than once
     but if the database is updated it will still be saved
     
     - parameter paramCheck: param to check in core data
     - parameter paramVal: param value to check
     - parameter entityName: name of entity to check
     */
    func alreadyExists(_ paramCheck: String, _ paramVal: String, _ entityName: String) -> Bool{
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return false
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        
        if paramCheck == "recnum"{
            fetchRequest.predicate = NSPredicate(format: "recnum == \(paramVal)")
        }
        else if paramCheck == "bed_id"{
            //this caused many problems and i have no idea why it wont accept the paramVal in the normal format
            fetchRequest.predicate = NSPredicate(format: "bed_id == %@", paramVal)
        }
        
        do {
            let numReturned = try managedContext.count(for: fetchRequest)
            if numReturned > 0 {
                return true
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return false
    }
    
    /**
     Saves plants if they do not already exist in Core Data, while this function is the reason the loading takes a second, it ensures that even if new plants are added the app will still work
     */
    func handlePlantSaving(){
        let val:Int? = fetchAmount(type: "Plant")
        
        //if no new plants have been added
        guard val != plantData!.plants.count else {
            lblLoading.isHidden = true
            lblInform.isHidden = true
            return
        }
        
        for i in 0..<plantData!.plants.count{
            if !alreadyExists("recnum", plantData!.plants[i].recnum!, "Plant") {
                save("Plant", [["recnum", plantData!.plants[i].recnum!], ["acid", plantData!.plants[i].acid ?? ""], ["accsta",plantData!.plants[i].accsta ?? ""], ["family", plantData!.plants[i].family ?? ""], ["genus", plantData!.plants[i].genus ?? ""], ["species", plantData!.plants[i].species ?? ""], ["infraspecific_epithet", plantData!.plants[i].infraspecific_epithet ?? ""], ["vernacular_name", plantData!.plants[i].vernacular_name ?? ""], ["cultivar_name", plantData!.plants[i].cultivar_name ?? ""], ["donor", plantData!.plants[i].donor ?? ""], ["latitude", plantData!.plants[i].latitude ?? ""], ["longitude", plantData!.plants[i].longitude ?? ""], ["country", plantData!.plants[i].country ?? ""], ["iso", plantData!.plants[i].iso ?? ""], ["sgu", plantData!.plants[i].sgu ?? ""], ["loc", plantData!.plants[i].loc ?? "",], ["alt", plantData!.plants[i].alt ?? ""], ["cnam", plantData!.plants[i].cnam ?? ""], ["cid", plantData!.plants[i].cid ?? ""], ["cdat", plantData!.plants[i].cdat ?? ""], ["bed", plantData!.plants[i].bed ?? ""], ["memoriam", plantData!.plants[i].memoriam ?? ""], ["redlist", plantData!.plants[i].redlist ?? ""], ["last_modified", plantData!.plants[i].last_modified ?? ""]])
            }
        }
        setAmount(type: "Plant", val: plantData!.plants.count)
        //As this is the bulk of the loading time
        lblLoading.isHidden = true
        lblInform.isHidden = true
    }
    
    /**
    Saves beds if they do not already exist in core data
     */
    func handleBedSaving(){
        let val:Int? = fetchAmount(type: "Bed")
        
        //if no new beds have been added
        guard val != plantBeds!.beds.count else {
            return
        }
        
        for i in 0..<plantBeds!.beds.count{
            if !alreadyExists("bed_id", plantBeds!.beds[i].bed_id!, "Bed"){
                save("Bed", [["bed_id", plantBeds!.beds[i].bed_id ?? ""],["last_modified", plantBeds!.beds[i].last_modified ?? ""],["latitude", plantBeds!.beds[i].latitude ?? ""],["longitude", plantBeds!.beds[i].longitude ?? ""], ["name", plantBeds!.beds[i].name ?? ""]])
            }
        }
        setAmount(type: "Bed", val: plantBeds!.beds.count)
    }
    
    /**
     Takes the beds from core data and adds it to the array that is used
     */
    func initBedFromCD(){
        var temp = BedData(bed_id: "", name: "", latitude: "", longitude: "", last_modified: "")
        fetch("Bed")
        
        plantBeds = BedArr()
        plantBeds!.beds = []
        
        //uses a temp value to store relevant information and then append for each value in core data
        for i in 0..<cachedBeds.count{
            temp.bed_id = cachedBeds[i].value(forKey: "bed_id") as? String ?? ""
            temp.name = cachedBeds[i].value(forKey: "name") as? String ?? ""
            temp.latitude = cachedBeds[i].value(forKey: "latitude") as? String ?? ""
            temp.longitude = cachedBeds[i].value(forKey: "longitude") as? String ?? ""
            temp.last_modified = cachedBeds[i].value(forKey: "last_modified") as? String ?? ""
            plantBeds!.beds.append(temp)
        }
        cachedBeds.removeAll()
    }
    
    /**
     Takes the plants form core data and adds them to the array that is used
     */
    func initPlantFromCD(){
        var temp = PlantData(recnum: "", acid: "", accsta: "", family: "", genus: "", species: "", infraspecific_epithet: "", vernacular_name: "", cultivar_name: "", donor: "", latitude: "", longitude: "", country: "", iso: "", sgu: "", loc: "", alt: "", cnam: "", cid: "", cdat: "", bed: "", memoriam: "", redlist: "", last_modified: "")
        fetch("Plant")
        
        plantData = PlantArr()
        plantData!.plants = []
        //uses a temp value to store relevant information and then append for each value in core data
        for i in 0..<cachedPlants.count{
            temp.recnum = cachedPlants[i].value(forKey: "recnum") as? String
            temp.acid = cachedPlants[i].value(forKey: "acid") as? String ?? ""
            temp.accsta = cachedPlants[i].value(forKey: "accsta") as? String ?? ""
            temp.family = cachedPlants[i].value(forKey: "family") as? String ?? ""
            temp.genus = cachedPlants[i].value(forKey: "genus") as? String ?? ""
            temp.species = cachedPlants[i].value(forKey: "species") as? String ?? ""
            temp.infraspecific_epithet = cachedPlants[i].value(forKey: "infraspecific_epithet") as? String ?? ""
            temp.vernacular_name = cachedPlants[i].value(forKey: "vernacular_name") as? String ?? ""
            temp.cultivar_name = cachedPlants[i].value(forKey: "cultivar_name") as? String ?? ""
            temp.donor = cachedPlants[i].value(forKey: "donor") as? String ?? ""
            temp.latitude = cachedPlants[i].value(forKey: "latitude") as? String ?? ""
            temp.longitude = cachedPlants[i].value(forKey: "longitude") as? String ?? ""
            temp.country = cachedPlants[i].value(forKey: "country") as? String ?? ""
            temp.iso = cachedPlants[i].value(forKey: "iso") as? String ?? ""
            temp.sgu = cachedPlants[i].value(forKey: "sgu") as? String ?? ""
            temp.loc = cachedPlants[i].value(forKey: "loc") as? String ?? ""
            temp.alt = cachedPlants[i].value(forKey: "alt") as? String ?? ""
            temp.cnam = cachedPlants[i].value(forKey: "cnam") as? String ?? ""
            temp.cid = cachedPlants[i].value(forKey: "cid") as? String ?? ""
            temp.cdat = cachedPlants[i].value(forKey: "cdat") as? String ?? ""
            temp.bed = cachedPlants[i].value(forKey: "bed") as? String ?? ""
            temp.memoriam = cachedPlants[i].value(forKey: "memoriam") as? String ?? ""
            temp.redlist = cachedPlants[i].value(forKey: "redlist") as? String ?? ""
            temp.last_modified = cachedPlants[i].value(forKey: "last_modified") as? String ?? ""
            plantData!.plants.append(temp)
        }
        cachedPlants.removeAll()
        formatPlantData()
    }
    
    // MARK: Everything else
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make this view controller a delegate of the Location Manager
        locationManager.delegate = self as CLLocationManagerDelegate
        
        //set the level of accuracy for the user's location.
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        //Ask the location manager to request authorisation from the user.
        locationManager.requestWhenInUseAuthorization()
        
        //Once the user's location is being provided then ask for updates when the user
        //moves around.
        locationManager.startUpdatingLocation()
        
        //configure the map to show the user's location (with a blue dot).
        myMap.showsUserLocation = true
        
        //register the custom cell to be used in the table view
        theTable.register(UINib(nibName: "CustomCell", bundle: nil), forCellReuseIdentifier:"customCell")
        
        getBedData()
        getPlantData()
        getImageData()
            
        fetch("Favourited") //fetching favourited plants
        
        //Delay the running of this code to ensure that no arrays are nil in formatPlantData
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65){
            self.initPlantFromCD() //fetched the cached plants
            self.initBedFromCD() //fetch cached beds
        }
    }
    
    
    
    /**
     set  amount of either Beds or Plants depending on context, for saving
     
     - parameter type: name of entity to set
     - parameter type: value to set
     
     */
    func setAmount(type: String, val: Int){
        UserDefaults.standard.setValue(val, forKey: type)
    }
    /**
     Fetch amount of either Beds or Plants depending on context, for saving
     
     - parameter type: name of entity to fetch
     
     */
    func fetchAmount(type: String) -> Int{
        return UserDefaults.standard.integer(forKey: type)
    }
    
    /**
     Removes all data associated with a specific core data entitiy
     
     - parameter type: Entity to completely clear
     */
    func delAll(_ type: String){
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let fetchrequest = NSFetchRequest<NSFetchRequestResult>(entityName: type)
            let del = NSBatchDeleteRequest(fetchRequest: fetchrequest)
            let managedContext = appDelegate.persistentContainer.viewContext
            do {
                try managedContext.execute(del)
            } catch let error as NSError {
                print("Could not delete. \(error), \(error.userInfo)")
            }
            UserDefaults.standard.removeObject(forKey: type)
            updateTable()
        }
        
    
    
}




