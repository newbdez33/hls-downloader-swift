//
//  ContentView.swift
//  hls-downloader
//
//  Created by Jacky on 2019/11/01.
//  Copyright © 2019 illegal. All rights reserved.
//

import SwiftUI
import GCDWebServers

struct ContentView: View {
    @State private var url = "https://bitdash-a.akamaihd.net/content/sintel/hls/video/250kbit.m3u8"
    @State private var showPlayer = false
    
    let downloader = HLSDownloader()

    
    var body: some View {
        VStack {
            Text(verbatim:"HLS Downloader")
                .font(.title)
                .foregroundColor(.green)
            HStack {
                Text(verbatim:"HLS streaming download")
                    .font(.subheadline)
                Text(verbatim:"also support encrypted")
                    .font(.subheadline)
            }
            HStack {
                Text(verbatim:"Url")
                TextField("URL", text: $url)
                    .font(Font.system(size: 11, design: .default))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            Button(action: {
                print("URL:\(self.url)")
                if let documentsPathString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                    let path = "\(documentsPathString)/hls-downloaded/\(UUID().uuidString)"
                    if FileManager.default.fileExists(atPath: path) {
                        print("file exists")
                        return
                    }
                    self.downloader.mediaPath = path
                    self.downloader.m3u8URL = self.url
                    let app = UIApplication.shared.delegate as! AppDelegate
                    self.downloader.sessionManager = app.sessionManager
                    self.downloader.start()
                    self.downloader.downloadSuccessed = {
                        self.downloader.startServer()
                        self.showPlayer = true
                    }
                    self.downloader.downloadFailed = {
                        print("Failed download playlist.")
                    }
                    self.downloader.downloaderProgress = { progress in
                        print("\(progress)")
                    }
                }
                
            }) {
                Text(verbatim:"Download")
            }
            if showPlayer {
                PlayerContainerView(url: URL(string: "http://127.0.0.1:8080/playlist.m3u8")!).frame(height:300)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
