//
//  CKCollectionViewCell.swift
//

import UIKit

class CKCollectionViewCell: UICollectionViewCell {

    @IBOutlet var plusButton: UIButton!
    @IBOutlet var imageView: UIImageView!

    override var isSelected: Bool {
        didSet {
            if (isSelected) && (self.reuseIdentifier == "Cell" ) {
//                self.layer.borderColor = UIColor(red: CGFloat(0.26), green: CGFloat(0.26), blue: CGFloat(0.26), alpha: CGFloat(1.0)).cgColor
                self.layer.borderColor = self.tintColor.cgColor
                self.layer.cornerRadius = 5.0
                self.layer.borderWidth = 2.0
            } else{
                self.layer.borderColor = UIColor.clear.cgColor
                self.layer.borderWidth = 0.0
            }
        }
    }
    internal func style(image: UIImage) {
        imageView.image = image
        if self.isSelected == true {
            self.layer.borderWidth = 0.0
            self.layer.borderColor = UIColor.clear.cgColor;
        }
    }
    
    internal func styleAddButton() {
//        self.layer.borderWidth = 2.0
//        self.layer.cornerRadius = 5.0
//        self.layer.borderColor = self.plusButton.tintColor.cgColor
    }
    
}
