
import Foundation
import Network

protocol SessionManagrDelegate: class {
    func didReceiveData(data: Data)
}

class SessionManagr {
    var socket: NWConnection?
    var hostUDP: NWEndpoint.Host = "192.168.3.179"//"34.87.150.46"
    var portUDP: NWEndpoint.Port = 6667
    weak var delegate: SessionManagrDelegate?
    var timer: Timer?
    
    init() {
        socket = NWConnection(host: hostUDP, port: portUDP, using: .udp)
        socket?.stateUpdateHandler = { [weak self] (newState) in
            print("This is stateUpdateHandler:")
            switch (newState) {
            case .ready:
                print("State: Ready\n")
                self?.receiveUDP()
            case .setup:
                print("State: Setup\n")
            case .cancelled:
                print("State: Cancelled\n")
            case .preparing:
                print("State: Preparing\n")
            default:
                print("ERROR! State not defined!\n")
            }
        }
        socket?.start(queue: .global())
        
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(pingpong), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    func stop() {
        socket?.cancel()
        timer?.invalidate()
    }
    
    func sendUDP(_ content: Data) {
        print(content.count)
        socket?.send(content: content, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
//                print("Data was sent to UDP")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
        
    }
    
    func receiveUDP() {
        socket?.receiveMessage { (data, context, isComplete, error) in
            self.receiveUDP()
            DispatchQueue(label: "\(Date().timeIntervalSince1970.description)").async { [weak self] in
                if (isComplete) {
                    if let data = data {
                        print("did receive data")
                        self?.delegate?.didReceiveData(data: data)
                    } else {
                        print("Data == nil")
                    }
                }
            }
        }
    }
    
    @objc func pingpong() {
        var roomId = Data(byteArray(HomeViewController.user?.roomId ?? 0)).subdata(in: 4..<8)
        roomId.insert(0, at: 0)
        sendUDP(roomId)
    }
}
