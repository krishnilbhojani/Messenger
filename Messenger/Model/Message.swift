//
//  Message.swift
//  Messenger
//
//  Created by Krishnil Bhojani on 25/04/20.
//  Copyright © 2020 Krishnil Bhojani. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject{
    var text: String?
    var toId: String?
    var fromId: String?
    var timeStamp: NSNumber?
    
    init(dictionary: [String: Any]) {
        self.text = dictionary["text"] as? String
        self.toId = dictionary["toId"] as? String
        self.fromId = dictionary["fromId"] as? String
        self.timeStamp = dictionary["timeStamp"] as? NSNumber
    }
    
    func chatPartnerId() -> String?{
        if fromId == Auth.auth().currentUser?.uid{
            return toId
        }else{
            return fromId
        }
    }
}
