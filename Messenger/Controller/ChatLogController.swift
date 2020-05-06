//
//  ChatViewController.swift
//  Messenger
//
//  Created by Krishnil Bhojani on 25/04/20.
//  Copyright © 2020 Krishnil Bhojani. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVKit

class ChatLogController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
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
    }
    
    override var inputAccessoryView: UIView?{
        get{
            scrollToBottom()
            return inputContainerView
        }
    }
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .white
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
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let videoUrl = info[.mediaURL] as? URL{
            uploadVideoToFirebaseStorage(using: videoUrl)
        }else if let uploadImage = info[.editedImage] as? UIImage{
            uploadToFirebaseStorage(using: uploadImage) { (imageUrl) in
                self.sendImageMessage(using: imageUrl, and: uploadImage)
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadVideoToFirebaseStorage(using videoFileUrl: URL){
        let videoName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("message_videos").child("\(videoName).mov")
        
        do{
            let data = try Data(contentsOf: videoFileUrl)
            let uploadTask = storageRef.putData(data, metadata: nil) { (storageMetadata, error) in
                if let error = error{
                    print(error)
                    return
                }
                storageRef.downloadURL { (url, error) in
                    if let error = error{
                        print(error)
                        return
                    }
                    
                    if let videoUrl = url?.absoluteString{
                        if let thumbnailImage = self.thumbnailImage(for: videoFileUrl){
                            self.uploadToFirebaseStorage(using: thumbnailImage) { (imageUrl) in
                                
                                let properties: [String: Any] = ["videoUrl": videoUrl, "imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height]
                                self.sendMessage(with: properties)
                            }
                        }
                    }
                    
                }
            }
            
            uploadTask.observe(.progress) { (snapshot) in
                if let fractionCompleted = snapshot.progress?.fractionCompleted{
                    let percentageCompleted = Int(fractionCompleted * 100)
                    self.navigationItem.title = String("\(percentageCompleted) %")
                }
            }
            uploadTask.observe(.success) { (snapshot) in
                self.navigationItem.title = self.user?.name
            }
        }catch let error{
            print(error)
            return
        }
    }
    
    private func thumbnailImage(for videoUrl: URL) -> UIImage?{
        let asset = AVAsset(url: videoUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do{
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTime(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
        }catch let err{
            print(err)
        }
        
        return nil
    }
    
    func uploadToFirebaseStorage(using image: UIImage, completion: @escaping (String) -> ()){
        let imageName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("message_images").child("\(imageName).jpeg")
        
        if let uploadData = image.jpegData(compressionQuality: 0.2){
            storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                if let error = error{
                    print(error)
                    return
                }
                storageRef.downloadURL { (url, error) in
                    if let error = error{
                        print(error)
                        return
                    }
                    if let urlString = url?.absoluteString{
                        completion(urlString)
                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("cancelled")
        dismiss(animated: true, completion:  nil)
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
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

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MessageCell
        cell.chatLogController = self
        
        if let url = user?.profileImageURL{
            cell.profileImageView.loadImageUsingCacheWithUrlString(url)
        }
        
        let message = messages[indexPath.row]
        cell.message = message
        
        setupCell(cell: cell, message: message)
        
        if let messageText = message.text{
            cell.textView.text = messageText
            cell.textView.isHidden = false
            cell.messageImageView.isHidden = true
            cell.bubbleViewWidthAnchor?.constant = estimateFrameForText(text: messageText).width + 28
            
        }else if let messageImageUrl = message.imageUrl{
            cell.bubbleView.backgroundColor = .lightGray
            cell.messageImageView.loadImageUsingCacheWithUrlString(messageImageUrl)
            cell.textView.isHidden = true
            cell.messageImageView.isHidden = false
            cell.bubbleViewWidthAnchor?.constant = 200
        }
        
        cell.playButton.isHidden = message.videoUrl == nil
        
        return cell
    }
    
    fileprivate func setupCell(cell: MessageCell, message: Message){
        if message.fromId == Auth.auth().currentUser?.uid{
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        
        let message = messages[indexPath.row]
        if let text = message.text{
            height = estimateFrameForText(text: text).height + 18
        }else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue{
            height = CGFloat(imageHeight/imageWidth * 200)
        }
        
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
        
        guard let text = inputTextField.text else { return }
        if text == "" { return }
        
        let properties: [String: Any] = ["text": text]
        sendMessage(with: properties)
    }
    
    private func sendImageMessage(using imageUrl: String, and image: UIImage){
        let properties: [String: Any] = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height]
        sendMessage(with: properties)
    }
    
    private func sendMessage(with properties: [String: Any]){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let messageId = db.collection("messages").document().documentID
        
        if let toId = user?.id{
            let timeStamp = Date().timeIntervalSince1970
            var values: [String: Any] = ["toId": toId, "fromId": uid, "timeStamp": timeStamp]
            
            properties.forEach({values[$0] = $1})
            
            db.collection("messages").document(messageId).setData(values) { (error) in
                if let error = error{
                    print(error)
                    return
                }
                
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

//    MARK: Custom Zooming logics
extension ChatLogController{
    //    MARK: Zoom logic 1
        
    //    var startingFrame: CGRect?
    //    var blackBackgroundView: UIView?
    //    var startingImageView: UIImageView?
    //
    //    func performZoomInForStartingImageView(startingImageView: UIImageView){
    //
    //        self.startingImageView = startingImageView
    //        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
    //
    //        let zoomingImageView = UIImageView(frame: startingFrame!)
    //        zoomingImageView.backgroundColor = .red
    //        zoomingImageView.image = startingImageView.image
    //        zoomingImageView.isUserInteractionEnabled = true
    //        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
    //
    //        if let keyWindow = UIApplication.shared.windows.last{
    //            print(UIApplication.shared.windows)
    //            blackBackgroundView = UIView(frame: keyWindow.frame)
    //            blackBackgroundView?.backgroundColor = .black
    //            blackBackgroundView?.alpha = 0
    //            keyWindow.addSubview(blackBackgroundView!)
    //
    //            keyWindow.addSubview(zoomingImageView)
    //
    //            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
    //                self.blackBackgroundView?.alpha = 1
    //                self.inputContainerView.alpha = 0
    //                self.startingImageView?.isHidden = true
    //
    //                let height = CGFloat(self.startingFrame!.height/self.startingFrame!.width * keyWindow.frame.width)
    //
    //                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
    //                zoomingImageView.center = keyWindow.center
    //            }, completion: nil)
    //
    //        }
    //
    //    }
    //
    //    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer){
    //        let zoomOutImageView = tapGesture.view
    //
    //        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
    //            zoomOutImageView?.layer.cornerRadius = 16
    //            zoomOutImageView?.layer.masksToBounds = true
    //
    //            zoomOutImageView?.frame = self.startingFrame!
    //            self.blackBackgroundView?.alpha = 0
    //
    //            self.inputContainerView.alpha = 1
    //        }) { (completed) in
    //            zoomOutImageView?.removeFromSuperview()
    //            self.startingImageView?.isHidden = false
    //        }
    //
    //    }
        
    //    MARK: Zoom logic 2
        func performZoomLogic(imageView: UIImageView){
            print("performing zoom in logic")
            let fullScreenImageViewController = FullScreenImageViewController()
            fullScreenImageViewController.imageView.image = imageView.image
            fullScreenImageViewController.modalPresentationStyle = .fullScreen
            fullScreenImageViewController.modalTransitionStyle = .crossDissolve
            present(fullScreenImageViewController, animated: true, completion: nil)
        }
}

extension ChatLogController{
    func playVideo(with videoUrl: URL){
        let videoPlayer = AVPlayer(url: videoUrl)
        let videoPlayerVC = AVPlayerViewController()
        videoPlayerVC.player = videoPlayer
        
        present(videoPlayerVC, animated: true) {
            videoPlayer.play()
        }
    }
}

//MARK: Another logic for zoom functionality (better than the first one in terms of functionality)
class FullScreenImageViewController: UIViewController {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()


    override func viewDidLoad() {
        super .viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(imageView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDismiss))
        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipeUpGesture.direction = .up
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipeDownGesture.direction = .down

        view.gestureRecognizers = [tapGesture ,swipeUpGesture, swipeDownGesture]

        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    @objc func handleDismiss(){
        dismiss(animated: true, completion: nil)
    }
}
