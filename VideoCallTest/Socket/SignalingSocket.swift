
import Foundation
import Network

protocol SignalingSocketDelegate: class {
    func socketConnected()
    func socketDisconnected(with error: String?)
    func didSendMessage(isSuccess: Bool)
    func didReciveMessage(response: ResponseModel)
}

class SignalingSocket {
    
    weak var delegate: SignalingSocketDelegate?
    
    var host: NWEndpoint.Host!
    var port: NWEndpoint.Port!
    var connection: NWConnection?
    
    init(delegate: SignalingSocketDelegate) {
        self.delegate = delegate
    }
    
    func startSocket(host: NWEndpoint.Host = "192.168.3.179", port: NWEndpoint.Port = 6666) {
        self.host = host
        self.port = port
        connection = NWConnection(host: host, port: port, using: .tcp)
        self.connection?.stateUpdateHandler = { [weak self] (newState) in
            debugPrint("This is stateUpdateHandler:")
            switch (newState) {
            case .ready:
                debugPrint("State: Ready\n")
                self?.delegate?.socketConnected()
                self?.receiveMessage()
            case .setup:
                debugPrint("State: Setup\n")
            case .cancelled:
                debugPrint("State: Cancelled\n")
                self?.connection = nil
                self?.delegate?.socketDisconnected(with: "")
            case .preparing:
                debugPrint("State: Preparing\n")
            default:
                self?.connection?.cancel()
                self?.connection = nil
                self?.delegate?.socketDisconnected(with: "Socket error")
                debugPrint("ERROR! State not defined!\n")
            }
        }
        self.connection?.start(queue: .global())
    }
    
    func sendMessage(message: String) {
        let data = message.data(using: String.Encoding.utf8)
        self.connection?.send(content: data, completion: .contentProcessed({ [weak self] (error) in
            self?.delegate?.didSendMessage(isSuccess: error == nil)
        }))
    }
    
    func receiveMessage() {
        self.connection?.receive(minimumIncompleteLength: 0, maximumLength: Int.max, completion: { [weak self] (data, content, isComplete, error) in
            if let data = data {
                print("receiveMessage \(String(data: data, encoding: .utf8) ?? "")")
                self?.receiveMessage()
                if var res = try? JSONDecoder().decode(ResponseModel.self, from: data) {
                    res.data = data
                    self?.delegate?.didReciveMessage(response: res)
                }
            } else {
                self?.connection?.cancel()
                self?.connection = nil
            }
        })
    }
}
