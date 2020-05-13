//
//  Extensions.swift
//  Messenger
//
//  Created by Krishnil Bhojani on 25/04/20.
//  Copyright © 2020 Krishnil Bhojani. All rights reserved.
//

import UIKit

let imageCache = NSCache<NSString, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(_ urlString: String) {
        
        self.image = nil
        
        //check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = cachedImage
            return
        }
        
        //otherwise fires of a new download
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error{
                print(error)
                return
            }
            
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data){
                    imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                    self.image = downloadedImage
                }
            }
            
        }.resume()
    }
}

