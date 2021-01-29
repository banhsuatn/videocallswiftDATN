//
//  ResponseModel.swift
//  VideoCallTest
//
//  Created by vhviet on 20/12/2020.
//

import Foundation

struct ResponseModel: Codable {
    var signalKey: String?
    var data: Data!
    
    enum CodingKeys: String, CodingKey {
        case signalKey
    }
}

struct ResponseInfoModel<T: Codable>: Codable {
    var signalKey: String?
    var data: T?
    
    enum CodingKeys: String, CodingKey {
        case signalKey
        case data
    }
}
