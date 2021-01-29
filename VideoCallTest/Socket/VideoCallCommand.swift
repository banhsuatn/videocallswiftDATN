
import Foundation


class VideoCallCommand {
    static let SHARE = VideoCallCommand()
    
    func login(user: UserInfoModel) -> String {
        return "{\"signalKey\":\"LOGIN\",\"data\":{\"userName\":\"\(user.userName ?? "\(Int.random(in: 0..<Int.max))")\",\"os\":\"\(user.os ?? "IOS")\",\"isWifi\":\"\(user.isWifi ?? false)\"}}\n"
    }
    
    func callRequest(list: [String]) -> String {
        if let jsonData = try? JSONEncoder().encode(list),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return "{\"signalKey\":\"CALL_REQUEST\",\"data\": \(jsonString)}\n"
        }
        return ""
    }
    
    func callResponse(isAccept: Bool)  -> String  {
        if let jsonData = try? JSONEncoder().encode(isAccept),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return "{\"signalKey\":\"CALL_RESPONSE\",\"data\": \(jsonString)}\n"
        }
        return ""
    }
}
