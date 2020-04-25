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

class LoadingIndicatorView: UIView{
    
    let loadingActivityIndicatorView: UIActivityIndicatorView = {
        let iv = UIActivityIndicatorView()
        iv.style = .large
        iv.color = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super .init(frame: frame)
        setupLayout()
    }
    
    func setupLayout(){
        alpha = 0
        backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 0.7)
        layer.cornerRadius = 16
//        layer.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 140).isActive = true
        widthAnchor.constraint(equalToConstant: 140).isActive = true
        
        addSubview(loadingActivityIndicatorView)
        addSubview(loadingLabel)
        
        loadingActivityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadingActivityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10).isActive = true
        
        loadingLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadingLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 30).isActive = true
    }
    
    func startLoading(){
        print("Loading Started")
        alpha = 1
        loadingActivityIndicatorView.startAnimating()
    }
    
    func stopLoading(){
        print("Loading Stopped")
        alpha = 0
        loadingActivityIndicatorView.stopAnimating()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
