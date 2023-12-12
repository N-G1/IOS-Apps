//
//  ViewController.swift
//  Simon Game
//
//  Created by Gill, Nathan on 31/10/2023.
//

import UIKit; import CoreData; import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var btnYellow: UIButton!
    @IBOutlet weak var btnBlue: UIButton!
    @IBOutlet weak var btnRed: UIButton!
    @IBOutlet weak var btnGreen: UIButton!
    
    @IBOutlet weak var btnYellowHighlight: UIButton!
    @IBOutlet weak var btnBlueHighlight: UIButton!
    @IBOutlet weak var btnRedHighlight: UIButton!
    @IBOutlet weak var btnGreenHighlight: UIButton!
    
    @IBOutlet var allGameBtns: [UIButton]!   //used in setup func
    @IBOutlet var overlayedBtns: [UIButton]! //used in setup func
    @IBOutlet var totalBtns: [UIButton]! //used in setup func
    @IBOutlet var startQuit: [UIButton]!
    
    @IBOutlet weak var btnStart: UIButton!
    
    @IBOutlet weak var lblMultiPlayerLost: UILabel!
    @IBOutlet weak var lblPlayerInfo: UILabel!
    @IBOutlet weak var lblPlayers: UILabel!
    @IBOutlet weak var lblEnd: UILabel!
    @IBOutlet weak var lblScore: UILabel!
    @IBOutlet weak var lblStage: UILabel!
    
    @IBOutlet weak var txtPlayers: UITextField!
    
    @IBAction func pressYellow(_ sender: Any) {checkUserInput(1)}
    @IBAction func pressBlue(_ sender: Any) {checkUserInput(2)}
    @IBAction func pressRed(_ sender: Any) {checkUserInput(3)}
    @IBAction func pressGreen(_ sender: Any) {checkUserInput(4)}
    
    @IBAction func btnStartPress(_ sender: Any) {
        if cameFromSegue && gameType == 1{
            btnStart.isHidden = true
            initFromGameBtn()
        }
        else if cameFromSegue && gameType == 2{
            guard Int(txtPlayers.text!)! >= 2 && Int(txtPlayers.text!)! <= 5 else {
                lblPlayerInfo.text = "Players can only be between 2 and 5!"
                return
            }
            
            //display game buttons on start
            displayAll()
            
            playerNo = Int(txtPlayers.text!)!
            currPlayer += 1
            lblPlayers.text = "Player: 1"
            lblPlayerInfo.isHidden = true
            txtPlayers.isHidden = true
            btnStart.isHidden = true
            
            //hide singleplayer highscore on start
            lblScore.isHidden = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.initFromGameBtn()
            }
            
        }
        else {
            for btn in allGameBtns{
                btn.isEnabled = false;
            }
            handleDisplayLoad()
        }
    }
    
    @IBAction func btnQuitPress(_ sender: Any) {
        performSegue(withIdentifier: "unwindGameMenu", sender: sender)
    }
    
    var sequence: [Int] = []
    var displayedSequence: [Int] = []
    
    var audioPlayer: AVAudioPlayer?
    var gameSounds = [String:URL]()
    
    var loopNo: Int!
    var lastNo: Int!
    var userLoopNo: Int!
    var amount: Int = 10
    var score: Int = 1
    
    var gameEnded: Bool!
    var btnsEnabled: Bool!
    var cameFromSegue: Bool!
    var gameStarted: Bool = false
    
    var gameType: Int!
    var playerScores: [Int] = []
    var playerNo: Int!
    var currPlayer: Int = 0

    /**
     Initialises the game from the start button
     */
    func initFromGameBtn(){
        cameFromSegue = false;
        gameStarted = true;
        generateSequence()
        nextButton()
    }
    /**
    Checks the input from the user, then checks if they are correct, correct and have completed the current section
     or are incorrect and handles appropriately

    - parameter pressed: The button the user has pressed in int format

    */
    func checkUserInput(_ pressed: Int){
        
        guard btnsEnabled == true else{ //btns enabled
            return
        }
        
        if pressed == displayedSequence[userLoopNo]{
            userLoopNo += 1
            //if user is correct and not at end of stage, continue
            if userLoopNo == displayedSequence.count && displayedSequence.count != amount{
                
                score += 1
                userLoopNo = 0
                nextButton()
            }
            //if user is correct and at the end of stage, genenerate new sequence
            else if userLoopNo == displayedSequence.count && displayedSequence.count == amount{
                var temp: Int!
                
                amount += 5
                temp = score + 1
                handleDisplayLoad() //workaround for display load setting score to 0
                score = temp
            }
            
        }else{
            //if user is incorrect 
            handleGameEnd()
        }
    }
    /**
        handles what happens at the end of the game, depends on game type
     */
    func handleGameEnd(){
        amount = 10
        
        //appended here and not in the else if below as playerScores would never be playerNo if it was appended afterwards
        if gameType == 2{
            playerScores.append(score)
        }
        //handles what takes place at the end of a singleplayer game
        if gameType == 1{
            gameEnded = true
            btnStart.isHidden = false;
            lblEnd.text = "Your score was \(score)"
            lblEnd.isHidden = false;
            save(score)
        }
        //handles what happens if a player fails but is not the last player in a multiplayer game
        else if gameType == 2 && playerScores.count != playerNo {
            currPlayer += 1
            lblPlayers.text = "Player: \(currPlayer)"
            lblMultiPlayerLost.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.handleDisplayLoad()
            }
        }
        //handles what takes place at the end of a multiplayer game
        else {
            var Winners: [Int] = []
            var winStr: String = ""
            var playerSingPlur: String = ""
            var winnersSingPlur: String = ""
            
            for i in 0...playerScores.count - 1 {
                if playerScores[i] == playerScores.max(){
                    Winners.append(i + 1)
                }
            }
            
            if Winners.count == 1{
                playerSingPlur = "Player"
                winnersSingPlur = "was the winner"
            }
            else {
                playerSingPlur = "Players"
                winnersSingPlur = "were the winners"
            }
            
            for i in 0..<Winners.count {
                if i != Winners.count - 1 {
                    winStr += "\(Winners[i]), "
                }
                else {
                    winStr += "\(Winners[i]) "
                }
                
            }
            hideAll()
            lblPlayerInfo.isHidden = false
            lblPlayerInfo.text! = "\(playerSingPlur) \(winStr)\(winnersSingPlur) with a score of \(playerScores.max() ?? 0)"
        }
        
    }
    
    /**
    Generates the sequence of buttons to be displayed for the current stage of the game
    */
    func generateSequence(){
        for _ in 1...amount{
            sequence.append(Int.random(in: 1..<5))
        }
        //sequence printing
        print("generated sequence: \(sequence)")
    }
    
    /**
    Appends next button to the list and then displays the next section of the game
    */
    func nextButton(){
        displayedSequence.append(sequence[lastNo])
        displaySequence()
    }
    
    /**
    Simple display function that makes use of a switch statement to flash the appropriate button and keep track of the next position for a colour to be added to the display sequence
    */
    func displaySequence(){
        btnsEnabled = false
        if loopNo < displayedSequence.count && gameEnded == false{
            
            loopNo += 1
            
            switch displayedSequence[loopNo - 1]{
            case 1:
                animateFlash(btn: btnYellowHighlight, "yellow")
            case 2:
                animateFlash(btn: btnBlueHighlight, "blue")
            case 3:
                animateFlash(btn: btnRedHighlight, "red")
            case 4:
                animateFlash(btn: btnGreenHighlight, "green")
            default:
                print("unknown type")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.displaySequence()
            }
        }
        else {
            //keeps track of the next position at the end of the list to append to display sequence
            lastNo = loopNo
            loopNo = 0
            btnsEnabled = true
            return
        }
    }
    
    func playSound(_ sound : String){
        if self.audioPlayer?.isPlaying == true {
            self.audioPlayer?.stop()
            self.audioPlayer = nil
        }
    
        setupAudioPlayer(toPlay: gameSounds[sound]!)
        self.audioPlayer?.play()
    }
    /**
    Animates the flash of the button by swapping it with a different coloured button overlaying it briefely before hiding it again
    */
    func animateFlash(btn : UIButton!, _ sound: String){
        //check if audio still playing when next button is passed purely to prevent overlap
        
        playSound(sound)
        
        UIView.animate(withDuration: 0.25, delay: 0.25, animations: {
            btn.alpha = 1.0
        })
        UIView.animate(withDuration: 0.25, delay: 0.25, animations: {
           btn.alpha = 0.0
        })
    }
    /**
    Handles the loading of the display and any resetting needed during play
    */
    func handleDisplayLoad(){
        //reset all vars used during gameplay
        gameEnded = false;
        sequence.removeAll()
        displayedSequence.removeAll()
        userLoopNo = 0; loopNo = 0; lastNo = 0; score = 0
        btnsEnabled = false;
        
        lblScore.text = "Highscore: \(UserDefaults.standard.integer(forKey: "score"))" //change
        
        //default to hidden as it will be shown in an additional function if it is needed, 
        //also prevents buttons reappearing if this fuction is called to reset while still on the display
        btnStart.isHidden = true
        lblEnd.isHidden = true
        btnStart.isHidden = true
        txtPlayers.isHidden = true
        lblPlayerInfo.isHidden = true
        lblMultiPlayerLost.isHidden = true
        
        if amount == 10{
            lblStage.text = "Stage: 1"
        }
        else {
            lblStage.text = "Stage: \(amount / 5)"
        }
        
        for btn in totalBtns {
            btn.isEnabled = true
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.black.cgColor
            btn.layer.cornerRadius = 0
        }
        
        for btn in allGameBtns {
            btn.alpha = 1
        }
        for btn in overlayedBtns {
            btn.alpha = 0.0
        }
        // in the case of the game already starting, immidiately start the next stage
        if gameStarted {
            generateSequence()
            nextButton()
        }
        //show the button to start if the user just came from the menu
        if cameFromSegue && gameType == 1 {
            btnStart.isHidden = false
        }
        //handle additional multiplayer setup
        if cameFromSegue && gameType == 2 {
            handleMultiLoad()
        }
        //hide the players label if it is single player
        if gameType == 1 || cameFromSegue {
            lblPlayers.text = ""
        }
        
    }
    /*
     Hides the buttons used in single player, written to a seperate function
     as its called upon pressing start and also on refresh
     */
    func hideSinglePlayerBtns(){
        lblPlayers.isHidden = false;
        lblScore.isHidden = true;
        lblStage.isHidden = true
    }
    /*
        Displays all buttons
     */
    func displayAll(){
        for btn in totalBtns{
            btn.isHidden = false
        }
        lblScore.isHidden = false
        lblStage.isHidden = false
    }
    /**
        Hides all buttons
     */
    func hideAll(){
        for btn in totalBtns{
            btn.isHidden = true
        }
        lblScore.isHidden = true
        lblStage.isHidden = true
    }
    
    func handleMultiLoad(){
        btnStart.isHidden = false
        txtPlayers.isHidden = false
        lblPlayerInfo.isHidden = false
        hideAll()
    }
    
    /**
    Saves the score of the user to be stored within core data and highscore displayed
    */
    func save(_ score: Int) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        //handles the highscore displayed during gameplay
        guard UserDefaults.standard.object(forKey: "score") != nil else {
            UserDefaults.standard.set(score, forKey: "score")
            return
        }
        
        if score > UserDefaults.standard.integer(forKey: "score"){
            UserDefaults.standard.set(score,forKey: "score")
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let leaderboard = NSEntityDescription.insertNewObject(forEntityName: "LeaderEntry", into: managedContext)
        
        let dFormatter = DateFormatter()
        dFormatter.dateFormat = "YY/MM/dd"
        let date = dFormatter.string(from: Date())
        
        
        leaderboard.setValue(date, forKeyPath: "date")
        leaderboard.setValue(score, forKeyPath: "score")
        
        do {
            try managedContext.save()
            print("SAVED")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func getAllMP3FileNameURLs() -> [String:URL] {
        var filePaths = [URL]() //URL array
        var audioFileNames = [String]() //String array
        var theResult = [String:URL]()

        let bundlePath = Bundle.main.bundleURL
        do {
            try FileManager.default.createDirectory(atPath: bundlePath.relativePath, withIntermediateDirectories: true)
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: bundlePath, includingPropertiesForKeys: nil, options: [])
            
            // filter the directory contents
            filePaths = directoryContents.filter{ $0.pathExtension == "mp3" }
            
            //get the file names, without the extensions
            audioFileNames = filePaths.map{ $0.deletingPathExtension().lastPathComponent }
        } catch {
            print(error.localizedDescription) //output the error
        }
        for loop in 0..<filePaths.count { //Build up the dictionary.
            theResult[audioFileNames[loop]] = filePaths[loop]
        }
        return theResult
    }
    
    func setupAudioPlayer(toPlay audioFileURL:URL) {
        do {
            try self.audioPlayer = AVAudioPlayer(contentsOf: audioFileURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Can't play the audio \(audioFileURL.absoluteString)")
            print(error.localizedDescription)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handleDisplayLoad()
        gameSounds = getAllMP3FileNameURLs()
        MenuViewController.handleButtonDisplay(startQuit)

    }
}

