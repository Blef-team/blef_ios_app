//
//  ErrorResponse.swift
//  Blef
//
//  Created by Adrian Golian on 17.04.20.
//  Copyright © 2020 Blef Team.
//

import Foundation

typealias JSON = [String: Any]

struct ErrorResponse {
    var message: String
}

extension ErrorResponse {
    init?(json: JSON) {
        guard let message = json["message"] as? String else {
            return nil
        }
        self.message = message
    }
}
