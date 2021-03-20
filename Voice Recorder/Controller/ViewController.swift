//
//  ViewController.swift
//  Voice Recorder
//
//  Created by Stefan Crudu on 20.02.2021.
//

import UIKit

protocol ViewControllerDelegate: class {
    func removeRecorderViewController()
    func addRecorderViewController()
    func updateList(with record: RecordModel)
}

class ViewController: UIViewController {
    
    lazy var audioManager: AudioManagerProtocol = {
        let manager = AudioManager()
        manager.delegate = self
        return manager
    }()
    
    @IBOutlet var footerView: UIView! {
        didSet {
            footerView.layer.cornerRadius = 20
        }
    }
    
    @IBOutlet var buttonView: UIView! {
        didSet {
            buttonView.layer.cornerRadius = buttonView.frame.width / 2
        }
    }
    
    @IBOutlet var buttonBackgroundView: UIView! {
        didSet {
            buttonBackgroundView.layer.cornerRadius = buttonBackgroundView.frame.width / 2
        }
    }
    
    @IBOutlet var recordButton: UIButton! {
        didSet {
            recordButton.backgroundColor = .red
            recordButton.layer.cornerRadius = recordButton.frame.width / 2
        }
    }
    
    @IBOutlet var heightRecordButtonConstraint: NSLayoutConstraint!
    @IBOutlet var widthRecordButtonContraint: NSLayoutConstraint!
    var recorderTopConstraint: NSLayoutConstraint?
    var playerBottomConstraint: NSLayoutConstraint?
    
    @IBOutlet var recordListTableView: UITableView! {
        didSet {
            audioManager.getRecordsList()
            recordListTableView.tableFooterView = UIView()
            recordListTableView.dataSource = self
            recordListTableView.delegate = self
        }
    }
    
    var listOfRecors: [RecordModel] = [] {
        didSet {
            recordListTableView.reloadData()
        }
    }
    
    var selectedIndexPath: IndexPath?
    
    private var recorderViewController: RecorderViewController? {
        return children.first(where: { $0 is RecorderViewController }) as? RecorderViewController
    }
    
    private var playerViewController: PlayerViewController? {
        return children.first(where: { $0 is PlayerViewController }) as? PlayerViewController
    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if recorderViewController != nil {
            removeRecorderViewController()
        } else {
            addRecordViewController()
        }
    }
    
    private func addRecordViewController() {
        guard
            let recorder: RecorderViewController = createViewController(identifier: "Recorder"),
            recorderViewController == nil
        else {
            return
        }
        recorder.parrent = self
        
        addChildController(controller: recorder, parent: self, view: view) { (recorderView) in
            recorderView.translatesAutoresizingMaskIntoConstraints = false
            
            recorderTopConstraint = recorderView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -115)
            
            NSLayoutConstraint.activate([
                recorderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                recorderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                recorderView.heightAnchor.constraint(equalToConstant: 149),
                recorderTopConstraint!
            ])
            
            view.layoutIfNeeded()
        }
        
        view.bringSubviewToFront(footerView)
        animateRecorderViewController(recorder) { _ in }
    }
    
    private func removeViewController(_ viewController: UIViewController?) {
        self.animateRecorderViewController(viewController) { (isAnimatedDone) in
            if isAnimatedDone {
                viewController?.willMove(toParent: nil)
                viewController?.removeFromParent()
                viewController?.view.removeFromSuperview()
            }
        }
    }
    
    private func animateRecorderViewController(_ viewController: UIViewController?, completion: @escaping (Bool) -> Void) {
        guard viewController == recorderViewController else { completion(true); return }
        
        if recorderTopConstraint?.constant == -115 {
            recorderTopConstraint?.constant -= 149
            
        } else {
            recorderTopConstraint?.constant += 149
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
        }, completion: { (isDone) in
            if isDone {
                completion(true)
            }
        })
    }
    
    
    private func addChildController(controller: UIViewController, parent: UIViewController, view: UIView, configure: (UIView) -> Void) {
        parent.addChild(controller)
        view.addSubview(controller.view)
        controller.didMove(toParent: parent)
        
        configure(controller.view)
    }
    
    private func createViewController<T: UIViewController>(identifier: String) -> T? {
        return storyboard?.instantiateViewController(identifier: identifier) as? T
    }
    
    private func attachPlayerViewControllerToCell(at indexPath: IndexPath, tableView: UITableView, viewController: (PlayerViewController?) -> Void) {
        [playerViewController, recorderViewController].forEach(removeViewController)
        
        if let controller: PlayerViewController = createViewController(identifier: "AudioPlayer"), let cell = tableView.cellForRow(at: indexPath) {
            viewController(controller)
            
            tableView.beginUpdates()
            
            addChildController(controller: controller, parent: self, view: cell.contentView) { (playerView) in
                playerView.translatesAutoresizingMaskIntoConstraints = false
                
                playerBottomConstraint = playerView.bottomAnchor.constraint(equalTo: cell.bottomAnchor)
                
                NSLayoutConstraint.activate([
                    playerView.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
                    playerView.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                    playerView.topAnchor.constraint(equalTo: cell.topAnchor),
                    playerBottomConstraint!
                ])
                
                playerView.layoutIfNeeded()
            }
            
            tableView.endUpdates()
        } else {
            viewController(nil)
        }
    }
}

// MARK: - UITableViewDataShource -

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfRecors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "record", for: indexPath)
        cell.textLabel?.text = "\(listOfRecors[indexPath.row].name)"
        return cell
    }
}

// MARK: - UITableViewDelegate -

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        attachPlayerViewControllerToCell(at: indexPath, tableView: tableView) { viewController in
            guard let vc = viewController else { return }
            
            vc.dataSource = listOfRecors[indexPath.row]
            vc.audioManager = audioManager
            vc.delegate = self
            
            self.selectedIndexPath = indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let selectedRows = tableView.indexPathsForSelectedRows, selectedRows.contains(indexPath) {
            return 149
        } else {
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Delete") { [weak self] (action, view, completionHandler) in
            self?.audioManager.deleteRecord(record: (self?.listOfRecors[indexPath.row])!)
            completionHandler(true)
        }
        action.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [action])
    }
}

// MARK: - AudioManagerDelegate -

extension ViewController: AudioManagerDelegate {
    func showError(message: String) {
        let alert = UIAlertController(title: "Ups..", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateListOfRecords(with list: [RecordModel]) {
        listOfRecors = list
        recordListTableView.reloadData()
    }
    
    func didRemoveRecord(record: RecordModel) {
        if let index = listOfRecors.firstIndex(where: {$0.path == record.path}) {
            recordListTableView.beginUpdates()
            listOfRecors.remove(at: index)
            recordListTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .middle)
            recordListTableView.endUpdates()
        }
    }
}

// MARK: - ViewControllerDelegate -

extension ViewController: ViewControllerDelegate {
    func updateList(with record: RecordModel) {
        listOfRecors.insert(record, at: 0)
    }
    
    func removeRecorderViewController() {
        if let recorderVC = recorderViewController {
            DispatchQueue.main.async {
                self.removeViewController(recorderVC)
                
                UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveLinear], animations: {
                    self.heightRecordButtonConstraint.constant = 52
                    self.widthRecordButtonContraint.constant = 52
                    self.footerView.layer.cornerRadius = 20
                    self.recordButton.layoutIfNeeded()
                    self.recordButton.layer.cornerRadius = self.recordButton.frame.width / 2
                })
            }
        }
    }
    
    func addRecorderViewController() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveLinear], animations: {
                self.heightRecordButtonConstraint.constant = 36
                self.widthRecordButtonContraint.constant = 36
                self.recordButton.layer.cornerRadius = 5
                self.footerView.layer.cornerRadius = 0
                self.recordButton.layoutIfNeeded()
            })
        }
    }
}
