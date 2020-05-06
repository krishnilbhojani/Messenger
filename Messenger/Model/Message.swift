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
    var imageUrl: String?
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    var videoUrl: String?
    
    init(dictionary: [String: Any]) {
        self.text = dictionary["text"] as? String
        self.toId = dictionary["toId"] as? String
        self.fromId = dictionary["fromId"] as? String
        self.timeStamp = dictionary["timeStamp"] as? NSNumber
        
        self.imageUrl = dictionary["imageUrl"] as? String
        self.imageWidth = dictionary["imageWidth"] as? NSNumber
        self.imageHeight = dictionary["imageHeight"] as? NSNumber
        
        self.videoUrl = dictionary["videoUrl"] as? String
    }
    
    func chatPartnerId() -> String?{
        if fromId == Auth.auth().currentUser?.uid{
            return toId
        }else{
            return fromId
        }
    }
}
