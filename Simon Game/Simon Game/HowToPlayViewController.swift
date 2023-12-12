//
//  HowToPlayViewController.swift
//  Simon Game
//
//  Created by Gill, Nathan on 07/11/2023.
//

import UIKit

class HowToPlayViewController: UIViewController {
    @IBOutlet var btns: [UIButton]!
    
    @IBAction func btnBackPress(_ sender: Any) {
        performSegue(withIdentifier: "unwindHTPMenu", sender: sender)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        MenuViewController.handleButtonDisplay(btns)
    }
}
