//
//  LoginController+handlers.swift
//  Messenger
//
//  Created by Krishnil Bhojani on 24/04/20.
//  Copyright © 2020 Krishnil Bhojani. All rights reserved.
//

import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func handleRegister() {
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Form is not valid")
            loadingActivityIndicator.stopLoading()
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error{
                print(error)
                self.loadingActivityIndicator.stopLoading()
                return
            }
            print("Registered")
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            let storageRef = Storage.storage().reference().child("users").child(email).child("profileImage.jpeg")
            
            if let uploadData = self.profileImageView.image?.jpegData(compressionQuality: 0.1){
                storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                    if let error = error{
                        print(error)
                        self.loadingActivityIndicator.stopLoading()
                        return
                    }
                    print("Image Uploaded")
                    storageRef.downloadURL { (url, error) in
                        if let error = error{
                            print(error)
                            self.loadingActivityIndicator.stopLoading()
                            return
                        }
                        print("URL Downloaded")
                        guard let urlString = url?.absoluteString else { return }
                        let values = ["name": name, "email": email, "profileImageURL": urlString]
                        
                        self.registerUserIntoDatabase(with: uid, and: values)
                    }
                }
            }
        }
    }
    
    fileprivate func registerUserIntoDatabase(with uid: String, and values: [String: String]) {
        db.collection("users").document(uid).setData(values) { (error) in
            if let error = error{
                print(error)
                self.loadingActivityIndicator.stopLoading()
                return
            }
            print("Uaer Registered into database")
            self.loadingActivityIndicator.stopLoading()
            self.messagesController?.title = values["name"]
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage{
            profileImageView.image = editedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker")
        dismiss(animated: true, completion: nil)
    }
    
}
