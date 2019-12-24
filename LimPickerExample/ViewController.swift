//
//  ViewController.swift
//  LimPickerExample
//
//  Created by MyAdmin on 3/5/15.
//  Copyright (c) 2015 MyAdmin. All rights reserved.
//

import UIKit
import MediaPlayer
import MobileCoreServices
import AVFoundation

@objc
class ViewController: UIViewController,
//                        UIImagePickerControllerDelegate,
                        UINavigationControllerDelegate,
                        UIActionSheetDelegate,
                        CKImagePickerDelegate
{

    
    var limPicker:CKImagePickerViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @objc
    @IBAction func OpenCamera(sender: AnyObject) {
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        let photoAction = UIAlertAction(title: "Select photo from library", style: .default) { (_) in
            self.launchPickerController(sourceType: .photoLibrary)
        }

        alertController.addAction(photoAction)
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)){
            let takePictureAction = UIAlertAction(title: "Take a picture", style: .default) { (_) in
                self.launchPickerController(sourceType: .camera)
            }
            alertController.addAction(takePictureAction)
            let takeVideoAction = UIAlertAction(title: "Take a video", style: .default) { (_) in
                self.launchPickerController(sourceType: .camera)
            }
            alertController.addAction(takeVideoAction)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    func launchPickerController(sourceType: UIImagePickerController.SourceType) {
        let (navigationController, pickerViewController) = CKImagePickerViewController.ckImagePickerViewControllerWrappedInNavigationController()
        pickerViewController.delegate = self
        pickerViewController.setSourceType(type: sourceType)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    
    // MARK: - CKImagePickerViewController delegate
    

    // MARK: - CKImagePickerViewControllerDelegate Methods
    func ckImagePickerViewController(_ picker: CKImagePickerViewController, didFinishPickingWith images: [UIImage]) {
        DispatchQueue.main.async {
            // update some UI
            self.cleanProcessOnPicking()
        }
    }

    func ckImagePickerViewControllerDidCancel(_ picker: CKImagePickerViewController) {
        dismiss(animated: true) {

        }
    }

    func cleanProcessOnPicking() {
        dismiss(animated: true) {

        }
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
