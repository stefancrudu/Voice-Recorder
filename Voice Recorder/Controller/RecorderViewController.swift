//
//  RecorderViewController.swift
//  Voice Recorder
//
//  Created by Stefan Crudu on 24.02.2021.
//

import UIKit

class RecorderViewController: UIViewController {
    
    lazy var recorderManager: RecorderManagerProtocol = {
        let manager = RecorderManager()
        manager.delegate = self
        return manager
    }()
    
    weak var parrent: ViewControllerDelegate?
    
    @IBOutlet var recordNameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var waveView: WaveModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        recorderManager.requestPermison() { result in
            if !result {
                self.parrent?.removeRecorderViewController()
            } else {
                self.parrent?.addRecorderViewController()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.recorderManager.stopRecord()
        
        UIView.animate(withDuration: 0.2) {
            self.view.center.y += self.view.bounds.height
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupView() {
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
}

//MARK: - RecorderManagerDelegate -

extension RecorderViewController: RecorderManagerDelegate {
    func updateListWithNewRecord(_ record: RecordModel) {
        parrent?.updateList(with: record)
        parrent?.removeRecorderViewController()
    }
    
    func showError(message: String, actions: [UIAlertAction]?) {
        let alert = UIAlertController(title: "Ups..", message: message, preferredStyle: .alert)
        if let actions = actions {
            for action in actions {
                alert.addAction(action)
            }
        } else {
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        }
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateWaveView(amplitude: CGFloat, frequency: CGFloat) {
        waveView.waveColor = UIColor(named: "MainColor")!
        waveView.amplitude = amplitude
        waveView.frequency = frequency
    }
    
    func displayRecordName(with name: String) {
        recordNameLabel.text = name
    }
    
    func updateTimmer(with value: TimeInterval) {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        
        timeLabel.text = formatter.string(from: value)
    }
    
}
