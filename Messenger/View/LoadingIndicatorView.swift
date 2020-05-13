//
//  LoadingIndicatorView.swift
//  Messenger
//
//  Created by Krishnil Bhojani on 10/05/20.
//  Copyright © 2020 Krishnil Bhojani. All rights reserved.
//

import UIKit
import Lottie

class LoadingIndicatorView: UIView{
    
//    var animation: String? {
//        didSet{
//            guard let animationName = animation else { return }
//            illustrationAnimationView.animation = Animation.named(animationName)
//            startAnimating()
//        }
//    }
    
    let illustrationAnimationView: AnimationView = {
        let animationView = AnimationView()
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = .loop
        animationView.animation = Animation.named("loading")
        animationView.translatesAutoresizingMaskIntoConstraints = false
        return animationView
    }()
    
    let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 26)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super .init(frame: frame)
        setupLayout()
    }
    
    func setupLayout(){
        alpha = 0
        backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 0.85)
        layer.cornerRadius = 16
        layer.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 240).isActive = true
        widthAnchor.constraint(equalToConstant: 240).isActive = true
        
        addSubview(illustrationAnimationView)
        addSubview(loadingLabel)
        
        illustrationAnimationView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        illustrationAnimationView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        illustrationAnimationView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        illustrationAnimationView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        loadingLabel.topAnchor.constraint(equalTo: illustrationAnimationView.bottomAnchor).isActive = true
        loadingLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        loadingLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        loadingLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
    }
    
    func startAnimating(){
        print("Loading Started")
        alpha = 1
        illustrationAnimationView.play()
    }
    
    func stopAnimating(){
        print("Loading Stopped")
        alpha = 0
        illustrationAnimationView.stop()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
