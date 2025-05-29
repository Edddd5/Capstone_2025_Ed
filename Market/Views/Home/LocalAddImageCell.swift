//
//  LocalAddImageCell.swift
//  Market
//
//  Created by 장동혁 on 4/18/25.
//

import UIKit

class LocalAddImageCell: UICollectionViewCell {
    let addIconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "plus"))
        iv.tintColor = .systemGray
        iv.contentMode = .center
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.borderColor = UIColor.systemGray3.cgColor
        contentView.layer.borderWidth = 1
        contentView.layer.cornerRadius = 8
        contentView.addSubview(addIconView)
        
        NSLayoutConstraint.activate([
            addIconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            addIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addIconView.widthAnchor.constraint(equalToConstant: 30),
            addIconView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
