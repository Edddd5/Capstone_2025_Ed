//
//  ImageCollectionViewCell.swift
//  Market
//
//  Created by 장동혁 on 4/18/25.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
