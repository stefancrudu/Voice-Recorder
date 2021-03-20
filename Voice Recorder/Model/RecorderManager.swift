//
//  RecorderManager.swift
//  Voice Recorder
//
//  Created by Stefan Crudu on 24.02.2021.
//

import Foundation
import UIKit
import AVFoundation

protocol RecorderManagerProtocol {
    func startRecord()
    func stopRecord()
    func requestPermison(completion: @escaping (Bool) -> Void)
}

protocol RecorderManagerDelegate: class {
    func displayRecordName(with name: String)
    func updateTimmer(with value: TimeInterval)
    func updateWaveView(amplitude: CGFloat, frequency: CGFloat)
    func showError(message: String, actions: [UIAlertAction]?)
    func updateListWithNewRecord(_ record: RecordModel)
}

class RecorderManager: RecorderManagerProtocol {
    
    weak var delegate: RecorderManagerDelegate?
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var fileName: String!
    var audioFilePath: URL!
    
    func startRecord() {
        fileName = generateName()
        delegate?.displayRecordName(with: String(fileName.dropLast(4)))
        
        audioFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        let recordSettings:[String:Any] = [AVFormatIDKey:kAudioFormatAppleLossless,
                                           AVEncoderAudioQualityKey:AVAudioQuality.max.rawValue,
                                           AVEncoderBitRateKey:320000,
                                           AVNumberOfChannelsKey:2,
                                           AVSampleRateKey:44100.0 ] as [String : Any]
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: recordSettings)
            audioRecorder.record()
            audioRecorder.isMeteringEnabled = true
            
            
            
            Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                guard self.audioRecorder != nil else { return }
                
                self.updateAudioWave()
                
                self.delegate?.updateTimmer(with: self.audioRecorder.currentTime)
            }
            
        } catch let error {
            delegate?.showError(message: "I can't record right now.", actions: nil)
            print(error.localizedDescription)
        }
    }
    
    func updateAudioWave() {
        guard  audioRecorder != nil else { return }
        audioRecorder.updateMeters()
        let peakPower = audioRecorder.peakPower(forChannel: 0)
        let frequency =  1 - (3 / -160 * peakPower)
        let avgPower = audioRecorder.peakPower(forChannel: 0)
        let amplitude = 1 - (1 / -160 * avgPower)
        
        delegate?.updateWaveView(amplitude: CGFloat(amplitude), frequency: CGFloat(frequency))
    }
    
    func stopRecord() {
        guard audioRecorder != nil else { return }
        let newRecord = RecordModel(name: String(fileName.dropLast(4)), path: audioFilePath, duration: Float(audioRecorder.currentTime), creationDate: Date())
        audioRecorder.stop()
        delegate?.updateListWithNewRecord(newRecord)
        audioRecorder = nil
    }
    
    func requestPermison(completion: @escaping (Bool) -> Void) {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            switch recordingSession.recordPermission {
            case .undetermined:
                recordingSession.requestRecordPermission { allowed in
                    if allowed {
                        self.startRecord()
                    } else {
                        completion(false)
                    }
                }
            case .denied:
                var actionsList: [UIAlertAction] = []
                let openSettingsAction = UIAlertAction(title: "Open settings", style: .default) { action in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
                actionsList.append(openSettingsAction)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                actionsList.append(cancelAction)
                
                delegate?.showError(message: "Please allow microphone usage from settings", actions: actionsList)
                completion(false)
                
                
            case .granted:
                startRecord()
                completion(true)
                
            @unknown default:
                delegate?.showError(message: "I don't have permision to record.", actions: nil)
            }
        } catch {
            completion(false)
        }
    }
    
    private func generateName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy - HH:mm:ss"
        let date = dateFormatter.string(from: Date())
        
        return "Record from \(date).m4a"
    }
}
