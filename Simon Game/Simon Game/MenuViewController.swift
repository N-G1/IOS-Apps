//
//  MenuViewController.swift
//  Simon Game
//
//  Created by Gill, Nathan on 03/11/2023.
//

import UIKit

class MenuViewController: UIViewController {
    @IBOutlet var btns: [UIButton]!
    var gameType: Int!
    
    @IBAction func unwindToMenu(unwindSegue: UIStoryboardSegue){}
    
    @IBAction func btnMultiClick(_ sender: Any) {
        gameType = 2
        performSegue(withIdentifier: "segueGame", sender: sender)
    }
    
    @IBAction func btnHTPClick(_ sender: Any) {
        performSegue(withIdentifier: "segueHowToPlay", sender: sender)
    }
    @IBAction func btnLeaderboardClick(_ sender: Any) {
        performSegue(withIdentifier: "segueLeader", sender: sender)
    }
    
    @IBAction func btnSingleClick(_ sender: Any) {
        gameType = 1
        performSegue(withIdentifier: "segueGame", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueGame"{
            let sndViewController = segue.destination as! ViewController
            sndViewController.cameFromSegue = true
            sndViewController.gameType = gameType
        }
    }
    
    public static func handleButtonDisplay(_ btns: [UIButton]){
        for btn in btns{
            btn.titleLabel?.font = UIFont(name:"Impact", size: 20)
            btn.backgroundColor = .systemMint
            btn.layer.cornerRadius = 5
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.black.cgColor
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        MenuViewController.handleButtonDisplay(btns)

    }
}
