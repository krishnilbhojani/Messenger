//
//  UserCell.swift
//  Messenger
//
//  Created by Krishnil Bhojani on 25/04/20.
//  Copyright © 2020 Krishnil Bhojani. All rights reserved.
//

import UIKit
import Firebase

class UserCell: UITableViewCell {
    
    let db = Firestore.firestore()
    
    var message: Message? {
        didSet{
            if let id = message?.chatPartnerId(){
                db.collection("users").document(id).addSnapshotListener { (documentSnapshot, error) in
                    if let error = error{
                        print(error)
                        return
                    }
                    if let data = documentSnapshot?.data(){
                        guard let profileImageURL = data["profileImageURL"] as? String, let name = data["name"] as? String else { return }
                        DispatchQueue.main.async {
                            self.titleLabel.text = name
                            self.profileImageView.loadImageUsingCacheWithUrlString(profileImageURL)
                            self.subtitleLabel.text = self.message?.text
                            if let seconds = self.message?.timeStamp?.doubleValue{
                                let timeStampDate = Date(timeIntervalSince1970: seconds)
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "hh:mm a"
                                self.timeLabel.text = dateFormatter.string(from: timeStampDate)
                            }
                        }
                    }
                }
            }
        }
    }
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .gray
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupLayouts()
    }
    
    private func setupLayouts(){
        addSubview(profileImageView)
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, timeLabel])
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        
        let labelStackView = UIStackView(arrangedSubviews: [headerStack, subtitleLabel])
        labelStackView.axis = .vertical
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelStackView)
        
        labelStackView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8).isActive = true
        labelStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        labelStackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
