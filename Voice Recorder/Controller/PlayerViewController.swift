//
//  PlayerViewController.swift
//  Voice Recorder
//
//  Created by Stefan Crudu on 23.02.2021.
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController, AVAudioPlayerDelegate {
    
    var controller = UIDocumentInteractionController()
    
    weak var delegate: ViewController?
    
    lazy var playerManager: PlayerManagerProtocol = {
        let manager = PlayerManager()
        manager.delegate = self
        return manager
    }()
    
    var audioManager: AudioManagerProtocol = AudioManager()
    
    var dataSource: RecordModel!
        
    @IBOutlet var audioNameLabel: UILabel! {
        didSet {
            audioNameLabel.text = dataSource.name
        }
    }
    
    @IBOutlet var currentTimeLabel: UILabel!
    
    @IBOutlet var totalTimeLabel: UILabel! {
        didSet {
            totalTimeLabel.text = formattedSeccounds(secounds: dataSource.duration)
        }
    }
    
    @IBOutlet var horizontalSlider: UISlider! {
        didSet {
            horizontalSlider.maximumValue = dataSource.duration
            horizontalSlider.setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
            horizontalSlider.setThumbImage(UIImage(systemName: "circle.fill"), for: .highlighted)
            horizontalSlider.tintColor = UIColor(named: "MainColor")
        }
    }
    
    @IBOutlet var playPauseButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        playerManager.prepareToPlay(from: dataSource.path)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerManager.stop()
    }
    
    @IBAction func horizontalSliderAction(_ sender: UISlider) {
        playerManager.currentTime(sender.value)
    }
    
    @IBAction func moreOptionsButtonPressed(_ sender: UIButton) {
        controller = UIDocumentInteractionController(url: dataSource.path)
        controller.presentOpenInMenu(from: CGRect.zero, in: self.view, animated: true)
    }
    
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        togglePlayPauseButtonImage()
        playerManager.togglePlay()
    }
    
    @IBAction func removeButtonPressed(_ sender: UIButton) {
        audioManager.deleteRecord(record: dataSource)
    }
    
    private func formattedSeccounds(secounds: Float) -> String {
        let time = Int(secounds)

        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)

        return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
    }
}

//MARK: - PlayerManagerDelegate -

extension PlayerViewController: PlayerManagerDelegate {
    func showError(message: String) {
        let alert = UIAlertController(title: "Ups..", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateTimeSlider(with value: Float) {
        DispatchQueue.main.async {
            self.horizontalSlider.value = value
        }
        currentTimeLabel.text = formattedSeccounds(secounds: value)
    }
    
    func togglePlayPauseButtonImage() {
        if playPauseButton.image(for: .normal) == UIImage(systemName: "pause.fill") {
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
}
