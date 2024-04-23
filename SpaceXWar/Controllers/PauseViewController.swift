//
//  PauseViewController.swift
//  SpaceXWar
//
//  Created by User on 22.04.2024.
//

import UIKit

protocol PauseVCDelegate {
    func pauseVCPlayButton(_ viewController: PauseViewController)
    func pauseVCMusicButton(_ viewController: PauseViewController)
}

class PauseViewController: UIViewController {
    
    @IBOutlet weak var musicButton: UIButton!
    
    var delegate: PauseVCDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func musicButtonPressed(_ sender: UIButton) {
        delegate.pauseVCMusicButton(self)
    }
    

    @IBAction func playButtonPressed(_ sender: UIButton) {
        delegate.pauseVCPlayButton(self)
    }
    
    @IBAction func storeButtonPressed(_ sender: UIButton) {
    }
    
    @IBAction func menuButtonPressed(_ sender: UIButton) {
    }
    
}
