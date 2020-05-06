//
//  TutorialCell.swift
//  Messenger
//
//  Created by Krishnil Bhojani on 27/04/20.
//  Copyright © 2020 Krishnil Bhojani. All rights reserved.
//

import UIKit
import Lottie

class TutorialCell: UICollectionViewCell {
    
    var animation: String? {
        didSet{
            guard let animationName = animation else { return }
            illustrationAnimationView.animation = Animation.named(animationName)
            illustrationAnimationView.play()
        }
    }
    
    let illustrationAnimationView: AnimationView = {
        let animationView = AnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.translatesAutoresizingMaskIntoConstraints = false
        return animationView
    }()
    
    override init(frame: CGRect) {
        super .init(frame: frame)
        setupViews()
    }
    
    fileprivate func setupViews(){
        addSubview(illustrationAnimationView)
        
        illustrationAnimationView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        illustrationAnimationView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        illustrationAnimationView.heightAnchor.constraint(equalTo: widthAnchor).isActive = true
        illustrationAnimationView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
