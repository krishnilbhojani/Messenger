//
//  ChatViewController.swift
//  Messenger
//
//  Created by Krishnil Bhojani on 25/04/20.
//  Copyright © 2020 Krishnil Bhojani. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
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
        guard let toId = user?.id else { return }
        
        db.collection("user-messages").document(uid).collection("messages").document(toId).addSnapshotListener{ (documentSnapshot, error) in
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
                            self.messages.append(message)
                            
                            self.timer?.invalidate()
                            self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleTimer), userInfo: nil, repeats: false)
                        }
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
            self.scrollToBottom()
        }
    }
    
    func scrollToBottom(){
        let indexPath = IndexPath(item: self.messages.count-1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
    }
    
    var messages = [Message]()
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter your message..."
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCollectionView()
//        setupInputs()
//        setupKeyboardObserver()
    }
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .white
//        containerView.autoresizingMask = .flexibleHeight
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.tintColor = .black
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .lightGray
        
        let uploadImageView = UIImageView()
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.image = UIImage(systemName: "photo.on.rectangle")
        uploadImageView.contentMode = .scaleAspectFit
        uploadImageView.tintColor = .black
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        
        containerView.addSubview(uploadImageView)
        containerView.addSubview(inputTextField)
        containerView.addSubview(sendButton)
        containerView.addSubview(separatorView)
        
        uploadImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        
        sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true

        inputTextField.leadingAnchor.constraint(equalTo: uploadImageView.trailingAnchor, constant: 8).isActive = true
        inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor).isActive = true
        inputTextField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true

        separatorView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        separatorView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        return containerView
    }()
    
    @objc func handleUploadTap(){
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    override var inputAccessoryView: UIView?{
        get{
            scrollToBottom()
            return inputContainerView
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let uploadImage = info[.editedImage] as? UIImage{
            uploadToFirebaseStorage(using: uploadImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func uploadToFirebaseStorage(using image: UIImage){
        print("Upload")
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("cancelled")
        dismiss(animated: true, completion:  nil)
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
//    func setupKeyboardObserver(){
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
//    }
//
//    override func viewDidDisappear(_ animated: Bool) {
//        super .viewDidDisappear(animated)
//
//        NotificationCenter.default.removeObserver(self)
//    }
//
//    @objc func handleKeyboardWillShow(notification: Notification){
//        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let keyboardDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double{
//
//            let window = UIApplication.shared.keyWindow
//            if let bottomPadding =  window?.safeAreaInsets.bottom{
//                inputContainerViewBottomAnchor?.constant = -keyboardFrame.height + bottomPadding
//                UIView.animate(withDuration: keyboardDuration) {
//                    self.view.layoutIfNeeded()
//                }
//            }
//        }
//    }
//
//    @objc func handleKeyboardWillHide(notification: Notification){
//        if let keyboardDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double{
//            inputContainerViewBottomAnchor?.constant = 0
//            UIView.animate(withDuration: keyboardDuration) {
//                self.view.layoutIfNeeded()
//            }
//        }
//    }
    
    func setupCollectionView(){
        collectionView.backgroundColor = .white
        collectionView.register(MessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.keyboardDismissMode = .interactive
        collectionView.alwaysBounceVertical = true
        
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
//    var inputContainerViewBottomAnchor: NSLayoutConstraint?
//
//    func setupInputs(){
//        let inputContainerView = UIView()
//        inputContainerView.backgroundColor = .white
//        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(inputContainerView)
//
//        inputContainerView.addSubview(inputTextField)
//        inputContainerView.addSubview(sendButton)
//        inputContainerView.addSubview(separatorView)
//
//        inputContainerViewBottomAnchor = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
//        inputContainerViewBottomAnchor?.isActive = true
//
//        inputContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
//        inputContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
//        inputContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
//
//        sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor).isActive = true
//        sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor).isActive = true
//        sendButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
//
//        inputTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 8).isActive = true
//        inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor).isActive = true
//        inputTextField.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor).isActive = true
//        inputTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor).isActive = true
//
//        separatorView.topAnchor.constraint(equalTo: inputContainerView.topAnchor).isActive = true
//        separatorView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor).isActive = true
//        separatorView.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
//        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
//
//    }

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
        
//        if let safeAreaInsets = UIApplication.shared.keyWindow?.safeAreaInsets{
//            let leftPadding = safeAreaInsets.left
//            let rightPadding = safeAreaInsets.right
//            let width = UIScreen.main.bounds.width - leftPadding - rightPadding
//            return CGSize(width: width, height: height)
//        }
        
        return CGSize(width: collectionView.frame.width, height: height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.reloadData()
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
//                self.db.collection("user-messages").document(uid).setData([messageId : 1], merge: true)
//                self.db.collection("user-messages").document(toId).setData([messageId : 1], merge: true)
                
                self.db.collection("user-messages").document(uid).collection("messages").document(toId).setData([messageId: timeStamp], merge: true)
                self.db.collection("user-messages").document(toId).collection("messages").document(uid).setData([messageId : timeStamp], merge: true)
                
                self.inputTextField.text = ""
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
}
