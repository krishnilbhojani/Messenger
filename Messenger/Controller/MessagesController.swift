//
//  ViewController.swift
//  Messenger
//
//  Created by Krishnil Bhojani on 24/04/20.
//  Copyright © 2020 Krishnil Bhojani. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {

    let cellId = "UserCell"
    
    let db = Firestore.firestore()
    
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let logoutImage = UIImage(named: "logout")
        let logoutButton = UIBarButtonItem(image: logoutImage, style: .plain, target: self, action: #selector(handleLogout))
        logoutButton.tintColor = .black
        logoutButton.imageInsets = UIEdgeInsets(top: 2, left: 0, bottom: -4, right: -6)
        navigationItem.leftBarButtonItem = logoutButton
        
        let newMessageImage = UIImage(systemName: "square.and.pencil")
        let newMessageButton = UIBarButtonItem(image: newMessageImage, style: .plain, target: self, action: #selector(handleNewMessage))
        newMessageButton.tintColor = .black
        navigationItem.rightBarButtonItem = newMessageButton
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        checkIfUserIsLoggedIn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    func setupNavBar(){
        let titleView = UIView()
        titleView.backgroundColor = .red
        titleView.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 16
        profileImageView.layer.masksToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        let nameLabel = UILabel()
        nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        
        let stackView = UIStackView(arrangedSubviews: [profileImageView, nameLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 5
        titleView.addSubview(stackView)
        
        stackView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        stackView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        
        // Filling details into navbar
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { (documentSnapshot, error) in
            if let error = error{
                print(error)
                return
            }
            if let data = documentSnapshot?.data(){
                nameLabel.text = data["name"] as? String
                if let urlString = data["profileImageURL"] as? String{
                    profileImageView.loadImageUsingCacheWithUrlString(urlString)
                }
            }
        }
        
        navigationItem.titleView = titleView
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            setupNavBar()
            observeMessages()
        }
    }
    
    func observeMessages(){
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("uid not found")
            return
        }
        
        db.collection("user-messages").document(uid).collection("messages").addSnapshotListener { (querySnapshot, error) in
            if let error = error{
                print(error)
                return
            }

            if let snapshotDocuments = querySnapshot?.documents{
                for doc in snapshotDocuments{
                    let data = doc.data()
                    guard let timeStampArray = Array(data.values) as? [Double] else { return }
                    let sortedArray = timeStampArray.sorted { (t1, t2) -> Bool in
                        return t1 > t2
                    }
                    
                    for element in data{
                        if element.value as? Double == sortedArray.first{
                            let messageId = element.key
                            self.fetchMessage(with: messageId)
                        }
                    }
                }
            }
        }
    }
    
    private func fetchMessage(with messageId: String){
        self.db.collection("messages").document(messageId).addSnapshotListener { (documentSnapshot, error) in
            if let error = error{
                print(error)
                return
            }
            if let data = documentSnapshot?.data(){
                let message = Message(dictionary: data)
                if let id = message.chatPartnerId(){
                    self.messagesDictionary[id] = message
                }
            }
            self.attemptReloadOfTable()
        }
    }
    
    func attemptReloadOfTable(){
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReload), userInfo: nil, repeats: false)
    }
    
    var timer: Timer?
    
    @objc func handleReload(){
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort { (m1, m2) -> Bool in
            guard let t1 = m1.timeStamp?.intValue, let t2 = m2.timeStamp?.intValue else { return false }
            return t1 > t2
        }
        
        DispatchQueue.main.async {
            print("reloaded")
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as! UserCell
        cell.message = messages[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let userId = messages[indexPath.row].chatPartnerId(){
            db.collection("users").document(userId).getDocument { (documentSnapshot, error) in
                if let error = error{
                    print(error)
                    return
                }
                if let data = documentSnapshot?.data(){
                    let user = User(dictionary: data)
                    user.id = userId
                    self.showChatViewController(with: user)
                }
            }
        }
    }
    
    func showChatViewController(with user: User){
        let chatViewController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatViewController.user = user
        navigationController?.pushViewController(chatViewController, animated: true)
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true, completion: nil)
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        let loginController = LoginController()
        loginController.messagesController = self
        loginController.modalPresentationStyle = .fullScreen
        present(loginController, animated: true, completion: nil)
    }

}

