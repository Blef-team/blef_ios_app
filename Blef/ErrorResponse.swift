//
//  ErrorResponse.swift
//  Blef
//
//  Created by Adrian Golian on 17.04.20.
//  Copyright © 2020 Blef Team.
//

import Foundation

struct ErrorResponse {
    var error: String
}

extension ErrorResponse {
    init?(json: JSON) {
        guard let message = json["error"] as? String else {
            return nil
        }
        self.error = message
    }
}
