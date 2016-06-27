//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by Razeware on 13/04/16.
//  Copyright (c) 2016 Razeware LLC. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
  
  // MARK: Properties
  
  // The scene draws the tiles and cookie sprites, and handles swipes.
  var scene: GameScene!
  
  // The level contains the tiles, the cookies, and most of the gameplay logic.
  // Needs to be ! because it's not set in init() but in viewDidLoad().
  var level: Level!
  var currentLevelNum = 1
  
  var movesLeft = 0
  var score = 0
  
  var tapGestureRecognizer: UITapGestureRecognizer!

  lazy var backgroundMusic: AVAudioPlayer? = {
    guard let url = NSBundle.mainBundle().URLForResource("Mining by Moonlight", withExtension: "mp3") else {
      return nil
    }
    do {
      let player = try AVAudioPlayer(contentsOfURL: url)
      player.numberOfLoops = -1
      return player
    } catch {
      return nil
    }
  }()
  
  
  // MARK: IBOutlets
  
  @IBOutlet weak var targetLabel: UILabel!
  @IBOutlet weak var movesLabel: UILabel!
  @IBOutlet weak var scoreLabel: UILabel!
  @IBOutlet weak var gameOverPanel: UIImageView!
  @IBOutlet weak var shuffleButton: UIButton!
  
  
  // MARK: IBActions
  
  @IBAction func shuffleButtonPressed(_: AnyObject) {
    shuffle()
    
    // Pressing the shuffle button costs a move.
    decrementMoves()
  }
  
  
  // MARK: View Controller Functions
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func shouldAutorotate() -> Bool {
    return true
  }
  
  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return [UIInterfaceOrientationMask.Portrait, UIInterfaceOrientationMask.PortraitUpsideDown]
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup view with level 1
    setupLevel(currentLevelNum)
    
    // Start the background music.
    backgroundMusic?.play()
  }
  
  
  // MARK: Game functions
  
  func setupLevel(levelNum: Int) {
    let skView = view as! SKView
    skView.multipleTouchEnabled = false
    
    // Create and configure the scene.
    scene = GameScene(size: skView.bounds.size)
    scene.scaleMode = .AspectFill
    
    // Setup the level.
    level = Level(filename: "Level_\(levelNum)")
    scene.level = level
    
    scene.addTiles()
    scene.swipeHandler = handleSwipe
    
    gameOverPanel.hidden = true
    shuffleButton.hidden = true
    
    // Present the scene.
    skView.presentScene(scene)
    
    // Start the game.
    beginGame()
  }
  
  func beginGame() {
    movesLeft = level.maximumMoves
    score = 0
    updateLabels()
    
    level.resetComboMultiplier()
    
    scene.animateBeginGame() {
      self.shuffleButton.hidden = false
    }
    
    shuffle()
  }
  
  func shuffle() {
    scene.removeAllCookieSprites()
    
    // Fill up the level with new cookies, and create sprites for them.
    let newCookies = level.shuffle()
    scene.addSpritesForCookies(newCookies)
  }
  
  // This is the swipe handler. MyScene invokes this function whenever it
  // detects that the player performs a swipe.
  func handleSwipe(swap: Swap) {
    // While cookies are being matched and new cookies fall down to fill up
    // the holes, we don't want the player to tap on anything.
    view.userInteractionEnabled = false
    
    if level.isPossibleSwap(swap) {
      level.performSwap(swap)
      scene.animateSwap(swap, completion: handleMatches)
    } else {
      scene.animateInvalidSwap(swap) {
        self.view.userInteractionEnabled = true
      }
    }
  }
  
  func beginNextTurn() {
    level.resetComboMultiplier()
    level.detectPossibleSwaps()
    view.userInteractionEnabled = true
    
    decrementMoves()
  }
  
  // This is the main loop that removes any matching cookies and fills up the
  // holes with new cookies. While this happens, the user cannot interact with
  // the app.
  func handleMatches() {
    // Detect if there are any matches left.
    let chains = level.removeMatches()
    
    // If there are no more matches, then the player gets to move again.
    if chains.count == 0 {
      beginNextTurn()
      return
    }
    
    // First, remove any matches...
    scene.animateMatchedCookies(chains) {
      
      // Add the new scores to the total.
      for chain in chains {
        self.score += chain.score
      }
      self.updateLabels()
      
      // ...then shift down any cookies that have a hole below them...
      let columns = self.level.fillHoles()
      self.scene.animateFallingCookies(columns) {
        
        // ...and finally, add new cookies at the top.
        let columns = self.level.topUpCookies()
        self.scene.animateNewCookies(columns) {
          
          // Keep repeating this cycle until there are no more matches.
          self.handleMatches()
        }
      }
    }
  }
  
  func updateLabels() {
    targetLabel.text = String(format: "%ld", level.targetScore)
    movesLabel.text = String(format: "%ld", movesLeft)
    scoreLabel.text = String(format: "%ld", score)
  }
  
  func decrementMoves() {
    movesLeft -= 1
    updateLabels()
    
    if score >= level.targetScore {
      gameOverPanel.image = UIImage(named: "LevelComplete")
      // Increment the current level, go back to level 1 if the current level
      // is the last one.
      currentLevelNum = currentLevelNum < NumLevels ? currentLevelNum+1 : 1
      showGameOver()
    } else if movesLeft == 0 {
      gameOverPanel.image = UIImage(named: "GameOver")
      showGameOver()
    }
  }
  
  func showGameOver() {
    gameOverPanel.hidden = false
    shuffleButton.hidden = true
    scene.userInteractionEnabled = false
    
    scene.animateGameOver() {
      self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideGameOver))
      self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }
  }
  
  func hideGameOver() {
    view.removeGestureRecognizer(tapGestureRecognizer)
    tapGestureRecognizer = nil
    
    gameOverPanel.hidden = true
    scene.userInteractionEnabled = true
    
    setupLevel(currentLevelNum)
  }
  
}