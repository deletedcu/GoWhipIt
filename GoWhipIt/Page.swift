//
//  Page.swift
//  GoWhipIt
//
//  Created by Star on 9/1/17.
//  Copyright © 2017 CommunicatieToegepast. All rights reserved.
//

import Foundation

class Page {
    
    var category: String
    var id: String
    var name: String
    var token: String
    
    init(category: String, id: String, name: String, token: String) {
        self.category = category
        self.id = id
        self.name = name
        self.token = token
    }
    
}
