//
//  ChatViewController.swift
//  Messenger
//
//  Created by Krishnil Bhojani on 25/04/20.
//  Copyright © 2020 Krishnil Bhojani. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout{
    
    private let cellId = "MessageCell"
    
    let db = Firestore.firestore()
    
    var user: User? {
        didSet{
            navigationItem.title = user?.name
            fetchMessages()
        }
    }
    
    func fetchMessages(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("user-messages").document(uid).addSnapshotListener{ (documentSnapshot, error) in
            if let error = error{
                print(error)
                return
            }
            self.messages.removeAll()
            if let data = documentSnapshot?.data(){
                for messageIdDoc in data{
                    self.db.collection("messages").document(messageIdDoc.key).addSnapshotListener{ (documentSnapshot, error) in
                        if let error = error{
                            print(error)
                            return
                        }
                        if let messageData = documentSnapshot?.data(){
                            let message = Message(dictionary: messageData)
                            if message.chatPartnerId() == self.user?.id{
                                self.messages.append(message)
                            }
                        }
                        
                        self.timer?.invalidate()
                        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleTimer), userInfo: nil, repeats: false)
                    }
                }
            }
        }
    }
    
    var timer: Timer?
    
    @objc func handleTimer(){
        self.messages.sort { (m1, m2) -> Bool in
            guard let t1 = m1.timeStamp?.intValue, let t2 = m2.timeStamp?.intValue else{ return false }
            return t1 < t2
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            let indexPath = IndexPath(item: self.messages.count-1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    var messages = [Message]()
    
    let inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter your message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return button
    }()
    
    let separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCollectionView()
        setupInputs()
    }
    
    func setupCollectionView(){
        collectionView.backgroundColor = .white
        collectionView.register(MessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
    }
    
    func setupInputs(){
        let inputContainerView = UIView()
        inputContainerView.backgroundColor = .white
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainerView)
        
        inputContainerView.addSubview(inputTextField)
        inputContainerView.addSubview(sendButton)
        inputContainerView.addSubview(separatorView)
        
        inputContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        inputContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        inputContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        inputTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 8).isActive = true
        inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor).isActive = true
        inputTextField.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor).isActive = true
        
        separatorView.topAnchor.constraint(equalTo: inputContainerView.topAnchor).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor).isActive = true
        separatorView.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MessageCell
        
        if let url = user?.profileImageURL{
            cell.profileImageView.loadImageUsingCacheWithUrlString(url)
        }
        
        if let messageText = messages[indexPath.row].text{
            cell.textView.text = messageText
            cell.bubbleViewWidthAnchor?.constant = estimateFrameForText(text: messageText).width + 28
            
            if messages[indexPath.row].fromId == Auth.auth().currentUser?.uid{
                cell.bubbleViewTrailingAnchor?.isActive = true
                cell.bubbleViewLeadingAnchor?.isActive = false
                cell.bubbleView.backgroundColor = cell.blueColor
                cell.textView.textColor = .white
                cell.profileImageView.isHidden = true
            }else{
                cell.bubbleViewTrailingAnchor?.isActive = false
                cell.bubbleViewLeadingAnchor?.isActive = true
                cell.bubbleView.backgroundColor = .lightGray
                cell.textView.textColor = .black
                cell.profileImageView.isHidden = false
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        if let text = messages[indexPath.row].text{
            height = estimateFrameForText(text: text).height + 18
        }
        return CGSize(width: collectionView.frame.width, height: height)
    }
    
    fileprivate func estimateFrameForText(text: String) -> CGRect{
        let size = CGSize(width: collectionView.frame.width/2 - 18, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    @objc func handleSend(){
        print("send")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let messageId = db.collection("messages").document().documentID
        
        if let toId = user?.id, let text = inputTextField.text{
            let timeStamp = Date().timeIntervalSince1970
            let values = ["toId": toId, "fromId": uid, "text": text, "timeStamp": timeStamp] as [String : Any]
            
            db.collection("messages").document(messageId).setData(values) { (error) in
                if let error = error{
                    print(error)
                    return
                }
                self.db.collection("user-messages").document(uid).setData([messageId : 1], merge: true)
                self.db.collection("user-messages").document(toId).setData([messageId : 1], merge: true)
                
                self.inputTextField.text = ""
            }
        }
    }
    
}
