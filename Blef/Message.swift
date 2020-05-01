//
//  Message.swift
//  Blef
//
//  Created by Adrian Golian on 24.04.20.
//  Copyright © 2020 Blef Team.
//

import Foundation

struct Message {
    var message: String
}

extension Message {
    init?(json: JSON) {
        guard let message = json["message"] as? String else {
            return nil
        }
        self.message = message
    }
}
