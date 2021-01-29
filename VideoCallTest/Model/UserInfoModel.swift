
import Foundation


struct UserInfoModel: Codable {
    var userName: String?
    var roomId: Int?
    var os: String?
    var isWifi: Bool?
    let status: Int?
    
    enum CodingKeys: String, CodingKey {
        case userName
        case os
        case isWifi
        case status
        case roomId
    }
}
