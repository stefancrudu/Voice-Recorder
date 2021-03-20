//
//  AdioManager.swift
//  Voice Recorder
//
//  Created by Stefan Crudu on 22.02.2021.
//

import Foundation
import AVFoundation


protocol AudioManagerProtocol {
    func getRecordsList()
    func deleteRecord(record: RecordModel)
}

protocol AudioManagerDelegate: class {
    func updateListOfRecords(with list: [RecordModel])
    func didRemoveRecord(record: RecordModel)
    func showError(message: String)
}

class AudioManager: AudioManagerProtocol {
    
    weak var delegate: AudioManagerDelegate?
    
    var records: [RecordModel] = []
    
    func getRecordsList() {
        let fileURLs = try? FileManager.default.contentsOfDirectory(at: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0], includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        let urls = fileURLs?.filter{
            let url = $0
            return !records.contains{ url == $0.path }
        }
        
        if let urls = urls {
            for url in urls {
                records.append(RecordModel(name: getFileNameFromURL(url), path: url, duration: getDurationOfRecord(path: url), creationDate: getDateDocument(url)))
            }
            delegate?.updateListOfRecords(with: records.sorted(by: {$0.creationDate > $1.creationDate}))
        }
    }
    
    func deleteRecord(record: RecordModel) {
        do {
            try FileManager.default.removeItem(at: record.path)
            records = records.filter{ $0.path != record.path}
            delegate?.didRemoveRecord(record: record)
        } catch {
            delegate?.showError(message: "I can't remove record \(record.name)")
            print(error.localizedDescription)
        }
    }
    
    private func getFileNameFromURL(_ path: URL) -> String {
        return String(path.lastPathComponent.dropLast(4))
    }
    
    private func getDateDocument(_ path: URL) -> Date {
        return try! path.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate!
    }
    
    func getDurationOfRecord(path: URL) -> Float {
        let asset = AVURLAsset(url: path)
        return Float(CMTimeGetSeconds(asset.duration))
    }
}

