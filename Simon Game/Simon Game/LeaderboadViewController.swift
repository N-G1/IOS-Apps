//
//  LeaderboadViewController.swift
//  Simon Game
//
//  Created by Gill, Nathan on 03/11/2023.
//

import UIKit; import CoreData

class LeaderboadViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var btns: [UIButton]!
    var tempLeader: [NSManagedObject] = []
    var leaderboard: [NSManagedObject] = []
    
    @IBAction func btnBackPress(_ sender: Any) {
        performSegue(withIdentifier: "unwindLeadMenu", sender: sender)
    }
    ///Fetches relevant information from core data to be displayed in the table
    func fetchData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"LeaderEntry")
        let sortDescriptor = NSSortDescriptor(key:"score", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            leaderboard = try managedContext.fetch(fetchRequest)
            //only displays top 15 scores from sorted list
            if leaderboard.count > 15 {
                leaderboard.removeLast(leaderboard.count - 15)
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return leaderboard.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        let entry = leaderboard[indexPath.row]
        let score = entry.value(forKeyPath: "score")
        let date = entry.value(forKeyPath: "date") as? String
        var content = UIListContentConfiguration.cell()
        //space in text is for appearance
        content.text = "\(score ?? "")                                                  \(date ?? "")"
        cell.contentConfiguration = content
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
        MenuViewController.handleButtonDisplay(btns)
    }
}
