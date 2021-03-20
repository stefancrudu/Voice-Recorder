//
//  PlayerManager.swift
//  Voice Recorder
//
//  Created by Stefan Crudu on 23.02.2021.
//

import Foundation
import AVFoundation

protocol PlayerManagerProtocol {
    func prepareToPlay(from path: URL)
    func togglePlay()
    func currentTime(_ value: Float)
    func stop()
}

protocol PlayerManagerDelegate: class {
    func updateTimeSlider(with value: Float)
    func togglePlayPauseButtonImage()
    func showError(message: String)
}

class PlayerManager: NSObject, PlayerManagerProtocol {
    
    weak var delegate: PlayerManagerDelegate?
    
    var audioPlayer: AVAudioPlayer!
    
    func prepareToPlay(from path: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
        } catch let error {
            delegate?.showError(message: "I can't get the audio record.")
            
            print(error.localizedDescription)
        }
    }
    
    func currentTime(_ value: Float) {
        audioPlayer.currentTime = TimeInterval(value)
    }
    
    func togglePlay() {
        guard audioPlayer != nil else {
            delegate?.showError(message: "I can't play this record.")
            delegate?.togglePlayPauseButtonImage()
            return
        }
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            self.audioPlayer.play()
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            self.delegate?.updateTimeSlider(with: Float(self.audioPlayer.currentTime))
        }
    }
    
    func stop() {
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying {
            audioPlayer.stop()
        }
    }
}

//MARK: - AVAudioPlayerDelegate -

extension PlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.togglePlayPauseButtonImage()
    }
}
