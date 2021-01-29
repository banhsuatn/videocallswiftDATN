
import UIKit
import Network
import AVKit
import mobileffmpeg

class ViewController: UIViewController {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var viewCamera: UIView!
    @IBOutlet weak var stackView: UIStackView!
    
    var peerCameraViews = [PeerItemCell]()
    var ex = [Int: String]()
    
    var socket: SignalingSocket!
    var session: SessionManagr!
    var listFriends = [UserInfoModel]()
    var currentUserShow: UserInfoModel?
    var captureSession: AVCaptureSession!
//    var audioEngine = AVAudioEngine()
//    var audioNode: AVAudioPlayerNode!
    var width = 480
    var height = 360
    var isFront = true
    
    var writer: AVAssetWriter?
    var input: AVAssetWriterInput!
    var inputAudio: AVAssetWriterInput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let videoSettings: [String : Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2);
        input.expectsMediaDataInRealTime = true
        
//        let audioSettings: [String : Any] = [
//            AVFormatIDKey: Int(kAudioFormatLinearPCM),
//            AVSampleRateKey: 8000,
//            AVNumberOfChannelsKey: 1,
//            AVLinearPCMIsBigEndianKey: false,
//            AVLinearPCMIsFloatKey: false,
//            AVLinearPCMBitDepthKey: 32,
//            AVLinearPCMIsNonInterleaved: false
//        ]
//        inputAudio = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
//        inputAudio.expectsMediaDataInRealTime = true
//
//        audioNode = AVAudioPlayerNode()
//        audioEngine.attach(audioNode)
//        let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)
//        audioEngine.connect(audioNode, to: audioEngine.mainMixerNode, format: format)
//        audioEngine.prepare()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        session = SessionManagr()
        session.delegate = self
        startSession(isFront: isFront)
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {  [weak self] in
//            guard let self = self else { return }
//            try? self.audioEngine.start()
//            if !self.audioNode.isPlaying {
//                self.audioNode.play()
//            }
//        }
    }
    
    func reloadVideo(listFriends: [UserInfoModel]) {
        self.listFriends.removeAll()
        for i in peerCameraViews {
            i.removeFromSuperview()
        }
        peerCameraViews.removeAll()
        for i in listFriends {
            if i.roomId == HomeViewController.user?.roomId,
               !(i.userName?.elementsEqual(HomeViewController.user?.userName ?? "") ?? false) {
                self.listFriends.append(i)
                let view = PeerItemCell(frame: CGRect(x: 0, y: 0, width: 125, height: 125))
                view.backgroundColor = .black
                view.user = i
                peerCameraViews.append(view)
            }
        }
        currentUserShow = self.listFriends.first
        
        for i in self.peerCameraViews {
            stackView?.addArrangedSubview(i)
        }
        view.layoutIfNeeded()
    }
    
    func startSession(isFront: Bool = true) {
        
        //camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: isFront ? .front : .back), let input = try? AVCaptureDeviceInput(device: camera)
            else {
                print("Unable to access back camera!")
                return
        }
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        let stillImageOutput = AVCaptureVideoDataOutput()
        stillImageOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "outputcamera"))

        if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput){
            captureSession.addInput(input)
            captureSession.addOutput(stillImageOutput)
            let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspect
            videoPreviewLayer.connection?.videoOrientation = .portrait
            viewCamera.layer.addSublayer(videoPreviewLayer)
            videoPreviewLayer.frame = self.viewCamera.bounds
        }
        
//        if let audioCaptureDevice : AVCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio), let audioInput = try? AVCaptureDeviceInput(device: audioCaptureDevice) {
//            if(captureSession.canAddInput(audioInput)){
//                captureSession.addInput(audioInput)
//                print("added input")
//            }
//            let audioOutput = AVCaptureAudioDataOutput()
//            audioOutput.setSampleBufferDelegate(self, queue: .global())
//            if(captureSession.canAddOutput(audioOutput)){
//                captureSession.addOutput(audioOutput)
//                print("added output")
//            }
//            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//                self?.captureSession.startRunning()
//            }
//        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    func makeHeader(data: Data, isVideo: Bool = true) -> Data {
        var result = Data(count: 20*1024)
        result[0] = 1
        result[1...4] = Data(byteArray(HomeViewController.user?.roomId ?? 0)).subdata(in: 4..<8)
        let username = (HomeViewController.user?.userName ?? "").data(using: .utf8) ?? Data()
        result[5...username.count] = username
        if isVideo {
            result[21] = 0
        } else {
            result[21] = 1
        }
        result[22] = 2
        if isVideo {
            result[23...25] = Data(byteArray(width)).subdata(in: 6..<8)
            result[25...27] = Data(byteArray(height)).subdata(in: 6..<8)
        } else {
            result[23...27] = "\(data.count)".data(using: .utf8) ?? Data()
        }
        
        result[32...data.count] = data
        return result
    }
    
    func playAudio() {
        
    }
    
    func toPCMBuffer(data: NSData) -> AVAudioPCMBuffer? {
        guard let audioFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 8000, channels: 1, interleaved: false), let PCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(data.length) / audioFormat.streamDescription.pointee.mBytesPerFrame) else { return nil }
        PCMBuffer.frameLength = PCMBuffer.frameCapacity
        let channels = UnsafeBufferPointer(start: PCMBuffer.floatChannelData, count: Int(PCMBuffer.format.channelCount))
        data.getBytes(UnsafeMutableRawPointer(channels[0]) , length: data.length)
        return PCMBuffer
    }
    
    @IBAction func btnSwitchCamera(_ sender: Any) {
        isFront = !isFront
        captureSession.stopRunning()
        captureSession = nil
        startSession(isFront: isFront)
    }
    @IBAction func actionBtn(_ sender: Any) {
        captureSession.stopRunning()
        session.stop()
        navigationController?.popToRootViewController(animated: true)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVAssetWriterDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if #available(iOS 13.0, *) {
            if #available(iOS 14.0, *) {
                var time = (Date().timeIntervalSince1970).description
                time.removeAll { (c) -> Bool in
                    return c == "."
                }
                let outputFileLocation = videoFileLocation(str: time)
                writer = try? AVAssetWriter(outputURL: outputFileLocation, fileType: .mp4)
                guard let writer = writer else {
                    return
                }
                if writer.canAdd(input) {
                    writer.add(input)
                    writer.startWriting()
                    writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                    input.append(sampleBuffer)
                    writer.finishWriting { [weak self] in
                        if let data = try? Data(contentsOf: outputFileLocation), data.count > 0, data.count < 19*1024 {
                            print("send data video \(data.count)")
                            self?.session.sendUDP(self?.makeHeader(data: data) ?? Data())
                        }
                    }
                    self.writer = nil
                }
            }
        }
    }
    
    func audioFileLocation(str: String) -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputUrl = URL(fileURLWithPath: documentsPath.appendingPathComponent("audioFile\(str)")).appendingPathExtension("wav")
        do {
            if FileManager.default.fileExists(atPath: videoOutputUrl.path) {
                try FileManager.default.removeItem(at: videoOutputUrl)
            }
        } catch {
            print(error)
        }
        return videoOutputUrl
    }
    
    func videoFileLocation(str: String) -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputUrl = URL(fileURLWithPath: documentsPath.appendingPathComponent("videoFile\(str)")).appendingPathExtension("mp4")
        do {
            if FileManager.default.fileExists(atPath: videoOutputUrl.path) {
                try FileManager.default.removeItem(at: videoOutputUrl)
            }
        } catch {
            print(error)
        }
        return videoOutputUrl
    }
}

extension ViewController: SessionManagrDelegate, ExecuteDelegate {
    func didReceiveData(data: Data) {
        if data.count < 33 {
            return
        }
        var username = (String(data: data.subdata(in: 5..<21), encoding: .utf8) ?? "")
        username.removeAll { (c) -> Bool in
            return c == "\0"
        }
        let isVideo = data[21] == 0
        let mediaData = data.subdata(in: 32..<data.count)
        if isVideo {
            var w: UInt8 = 0
            data.subdata(in: 23..<25).copyBytes(to:&w, count: MemoryLayout<UInt8>.size)
            var h: UInt8 = 0
            data.subdata(in: 25..<27).copyBytes(to:&h, count: MemoryLayout<UInt8>.size)
            var peer: PeerItemCell?
            for i in peerCameraViews {
                if i.user?.userName?.elementsEqual(username) ?? false {
                    peer = i
                }
            }
            if currentUserShow != nil, currentUserShow?.userName?.elementsEqual(username) ?? false {
                DispatchQueue.main.async {
                    peer?.isHidden = true
                }
                self.reader(data: mediaData, image: image)
            } else {
                for i in peerCameraViews {
                    if i.user?.userName?.elementsEqual(username) ?? false {
                        DispatchQueue.main.async {
                            i.isHidden = false
                        }
                        self.reader(data: mediaData, image: i.image)
                        break
                    }
                }
            }
            
        } else {
//            let str = String(data: data[23..<27], encoding: .utf8) ?? "0"
//            let c = Int(str) ?? 0
//            var time = (Date().timeIntervalSince1970).description
//            time.removeAll { (c) -> Bool in
//                return c == "."
//            }
//            let outputFileLocation = audioFileLocation(str: time)
//
//            try? mediaData.subdata(in: 0..<c).write(to: outputFileLocation)
//            if let file = try? AVAudioFile(forReading: outputFileLocation) {
//                self.audioNode.scheduleFile(file, at: nil, completionHandler: nil)
//            }
        }
    }
    
    func executeCallback(_ executionId: Int, _ returnCode: Int32) {
        DispatchQueue.init(label: Date().timeIntervalSince1970.description).async {  [weak self] in
            guard let self = self else { return }
            if let str = self.ex[executionId] {
                let asset = AVAsset(url: URL(fileURLWithPath: str))
                self.ex.removeValue(forKey: executionId)
                let assetReader = try? AVAssetReader(asset: asset)
                if let assetTrack = asset.tracks(withMediaType: .video).first,
                   let assetReader = assetReader {
                    let assetReaderOutputSettings = [
                        kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA)
                    ]
                    let assetReaderOutput = AVAssetReaderTrackOutput(track: assetTrack,
                                                                     outputSettings: assetReaderOutputSettings)
                    assetReaderOutput.alwaysCopiesSampleData = false
                    assetReader.add(assetReaderOutput)
                    
                    var images = [UIImage]()
                    assetReader.startReading()
                    
                    var sample = assetReaderOutput.copyNextSampleBuffer()
                    
                    while (sample != nil) {
                        if #available(iOS 13.0, *) {
                            if let image = sample?.imageBuffer { // The image is inverted here
                                let img = UIImage(ciImage: CIImage.init(cvImageBuffer: image))
                                images.append(img)
                                sample = assetReaderOutput.copyNextSampleBuffer()
                                DispatchQueue.main.async {  [weak self] in
                                    guard let self = self else { return }
                                    if self.image.tag == executionId {
                                        self.image.image = img
                                    } else {
                                        for i in self.peerCameraViews {
                                            if i.image.tag == executionId {
                                                i.image.image = img
                                                break
                                            }
                                        }
                                    }
                                    self.view.layoutIfNeeded()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func reader(data: Data, image: UIImageView) {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                        .userDomainMask,
                                                        true)
        if let file = paths.first {
            let t = Date().timeIntervalSince1970.description
            let urlStr = "\(file)/\(t).mkv"
            let urlStr2 = "\(file)/\(t).mp4"
            FileManager.default.createFile(atPath: urlStr, contents: data, attributes: nil)
            let id = Int(MobileFFmpeg.executeAsync("-i \(urlStr) -c:v mpeg4 \(urlStr2)", withCallback: self))
            DispatchQueue.main.async {  [weak self] in
                self?.ex[id] = urlStr2
                image.tag = id
            }
        }
    }
}
extension AVAudioPCMBuffer {
    static func create(from sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        
        if #available(iOS 13.0, *) {
            guard let description: CMFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
                  let sampleRate: Float64 = description.audioStreamBasicDescription?.mSampleRate,
                  let numberOfChannels: Int = description.audioChannelLayout?.numberOfChannels
            else { return nil }
            
            
            guard let blockBuffer: CMBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                return nil
            }

            let length: Int = CMBlockBufferGetDataLength(blockBuffer)
            
            let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: AVAudioChannelCount(numberOfChannels), interleaved: false)
            let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: AVAudioFrameCount(length))!
            buffer.frameLength = buffer.frameCapacity
            
            for channelIndex in 0...numberOfChannels - 1 {
                guard let channel: UnsafeMutablePointer<Float> = buffer.floatChannelData?[channelIndex] else { return nil }
                
                for pointerIndex in 0...length - 1 {
                    let pointer: UnsafeMutablePointer<Float> = channel.advanced(by: pointerIndex)
                    pointer.pointee = 100
                }
            }
            return buffer
        }
        return nil
    }
}
