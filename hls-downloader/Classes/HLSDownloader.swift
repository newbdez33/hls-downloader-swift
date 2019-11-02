//
//  HLSDownloader.swift
//  hls-downloader
//
//  Created by Jacky on 2019/11/01.
//  Copyright © 2019 illegal. All rights reserved.
//

import UIKit
import mamba
import Tiercel
import GCDWebServers

open class HLSDownloader {
    
    public var downloadSuccessed: (() -> Void)?
    public var downloadFailed: (() -> Void)?
    public var downloaderProgress: ((_ progress: Double) -> Void)?
    
    public var sessionManager: SessionManager?
    public var server: GCDWebServer? = nil
    
    let parser = PlaylistParser()
    public var m3u8URL = ""
    public var baseURL = ""
    public var mediaPath: String = "" {
      didSet {
        //m3u8Parser.identifier = directoryName
      }
    }
    public init() {
      
    }
    
    public func start() {
        if !(m3u8URL.hasPrefix("http://") || m3u8URL.hasPrefix("https://")) {
          print("Invalid URL.")
          return
        }
        guard let url = URL(string: self.m3u8URL) else {
            print("Invalid URL.")
            return
        }
        baseURL = url.deletingLastPathComponent().absoluteString
        
        DispatchQueue.global(qos: .background).async {
            do {
                let content = try Data(contentsOf: url)
                //let m3u8Content = try String(contentsOf: URL(string: self.m3u8URL)!, encoding: .utf8)
                //print(m3u8Content)
                self.parser.parse(playlistData: content, url: url) { (result) -> (Void) in
                    switch result {
                    case .parsedVariant(let variant):
                        self.handleVariantPlaylist(variant)
                        break
                    case .parsedMaster(let master):  //I don't have time to do it. so master playlist still someone to help with.  //Jacky 2019-11-01
                        self.handleMasterPlaylist(master)
                        break
                    case .parseError(let error):
                        print("parse m3u8 content error:\(error)")
                        break
                    }
                }
            } catch let error {
                print(error.localizedDescription)
                print("m3u8 file cannot read.")
            }
        }
    }
    
    public func startServer() {
        print("Start web server:\(mediaPath)")
        self.server = GCDWebDAVServer(uploadDirectory: mediaPath)
        self.server?.start()
    }
    
    private func handleMasterPlaylist(_ playlist: MasterPlaylist ) {
        print(playlist)
        print("Error: do not support master playlist for now.")
    }
    
    private func handleVariantPlaylist(_ playlist: VariantPlaylist ) {
        var resourceUrls:[URL] = []
        for( idx, tag ) in playlist.tags.enumerated() {
            if tag.tagDescriptor == mamba.PantosTag.EXT_X_KEY {
                if let key = tag.value(forKey: "URI"), let keyURL = URL(string: key) {
                    print("Found key uri:\(keyURL) at index \(idx)")
                    resourceUrls.append(keyURL)
                }
            }

            if tag.tagDescriptor == mamba.PantosTag.Location {
                if let seg = getSegmentMediaUrl(file:tag.tagData.stringValue()) {
                    print("Found segment:\(seg)")
                    resourceUrls.append(seg)
                }
            }
        }
        downloadSegmentUrls(urls: resourceUrls)
        writeLocalPlaylist(playlist)
    }
    
    private func getSegmentMediaUrl(file:String) -> URL? {
        if !(file.hasPrefix("http://") || file.hasPrefix("https://")) {
            let fullFileUrl = "\(baseURL)\(file)"
            return URL(string: fullFileUrl)
        }
        return URL(string: file)
    }
    
    private func downloadSegmentUrls(urls:[URL]) {
        guard let downloadManager = sessionManager else {
            print("error: downloadManager is not ready")
            return
        }
        
        let tasks = downloadManager.multiDownload(urls)
        downloadManager.progress(onMainQueue: true) { (manager) in
            //print("progress:\(manager.progress.fractionCompleted)")
            let progress = manager.progress.fractionCompleted
            self.downloaderProgress?(progress)
        }
        downloadManager.success(onMainQueue: true) { (manager) in
            //print(manager.completedTasks)
            self.downloadSuccessed?()
            manager.totalRemove()
        }
        downloadManager.failure(onMainQueue: true) { (manager) in
            if manager.status == .failed {
                self.downloadFailed?()
            }
        }
        tasks.success(onMainQueue: true) { (task) in
            //move to ${directoryName}
            self.moveLocalFilePath(downloaded: task.filePath, fileName: task.url.lastPathComponent)
        }
        tasks.failure(onMainQueue: true) { (task) in
            if task.status == .failed {
                print("Failure:\(task.filePath)")
            }
        }
    }
    
    private func writeLocalPlaylist(_ playlist: mamba.VariantPlaylist ) {
        //create new m3u8 playlist file
        var editable = playlist
        for( idx, tag ) in playlist.tags.enumerated() {
            if tag.tagDescriptor == mamba.PantosTag.EXT_X_KEY {
                if let key = tag.value(forKey: "URI"), let keyURL = URL(string: key) {
                    //print("Found key uri:\(keyURL) at index \(idx)")
                    var editTag = playlist.tags[idx]
                    editTag.set(value: keyURL.lastPathComponent, forValueIdentifier: PantosValue.uri)
                    editable.delete(atIndex: idx)
                    editable.insert(tag: editTag, atIndex: idx)
                }
            }

            if tag.tagDescriptor == mamba.PantosTag.Location {
                if let seg = getSegmentMediaUrl(file:tag.tagData.stringValue()) {
                    let editTag = PlaylistTag(tagDescriptor: PantosTag.Location, tagData:MambaStringRef(string: seg.lastPathComponent))
                    editable.delete(atIndex: idx)
                    editable.insert(tag: editTag, atIndex: idx)
                }
            }
        }
        
        let output = URL(fileURLWithPath: "\(mediaPath)/playlist.m3u8")
        do {
            self.prepareMediaDir()
            print("Write playlist to \(output)")
            try editable.write().write(to: output)
        }catch let err {
            print(err)
        }
        
    }
    
    private func prepareMediaDir() {
        do {
            var isDirectory: ObjCBool = true
            if !FileManager.default.fileExists(atPath: mediaPath, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(atPath: mediaPath, withIntermediateDirectories: true, attributes: nil)
            }
        }catch let err {
            print(err)
        }
    }
    
    private func moveLocalFilePath(downloaded:String, fileName:String) {
        do {
            self.prepareMediaDir()
            try FileManager.default.moveItem(atPath: downloaded, toPath: "\(mediaPath)/\(fileName)")
            print("Success:\(mediaPath)/\(fileName)")
        }catch let error {
            print("move downloaded file:\(error)")
        }
    }
    
}
