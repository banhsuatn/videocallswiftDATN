//
//  File.swift
//  VideoCallTest
//
//  Created by vhviet on 17/12/2020.
//

import AVKit
import Foundation
import VideoToolbox
import AVFoundation
import mobileffmpeg

class File {
    
    func reader() {
        let videoProfile = kVTProfileLevel_HEVC_Main_AutoLevel
        let codec = AVVideoCodecType.hevc
        
        let codecSettings = [AVVideoProfileLevelKey: videoProfile]
        
        let videoSettings = [AVVideoCodecKey: codec,
                             AVVideoCompressionPropertiesKey: codecSettings,
                             AVVideoWidthKey: 640,
                             AVVideoHeightKey: 480] as [String : Any]
        AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        
       
        
        
//        let track = AVAssetReaderTrackOutput(track: AVAsset(url: URL(string: "")!).tracks.first!, outputSettings: <#T##[String : Any]?#>)
//        let reader = try! AVAssetReader(asset: <#T##AVAsset#>)
//        reader.add(track)
//        reader.startReading()
//        while reader.status == .reading {
//            let buffer = track.copyNextSampleBuffer()
//        }
//        
    }
}
