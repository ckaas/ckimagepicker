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
class ViewController: UIViewController ,UIImagePickerControllerDelegate, UINavigationControllerDelegate,  UIActionSheetDelegate,   LimCameraImagePickerDelegate {

    
    var limPicker:LimCameraImagePicker?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    @IBAction func OpenCamera(sender: AnyObject) {
        var actionSheet:UIActionSheet
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)){
            actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil,otherButtonTitles:"Select photo from library", "Take a picture", "Take a video")
        } else {
            actionSheet = UIActionSheet(title: nil , delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil,otherButtonTitles:"Select photo from library")
        }
        actionSheet.delegate = self
        actionSheet.show(in: self.view)
    }
    
    
    // MARK: - imagePickerController and actionsheet Delegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as? String
        
        if mediaType == kUTTypeImage as String {
            limPicker = LimCameraImagePicker(nibName: "PickerView", bundle: Bundle.main)
            limPicker!.setSourceType(type: picker.sourceType)
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            limPicker!.addImage(image: image)
            limPicker!.delegate = self
            
            self.navigationController!.pushViewController(limPicker!, animated: true)
            picker.dismiss(animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: {})
            print("Video Taken!!!!");
        }
        
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        print("Title : \(String(describing: actionSheet.buttonTitle(at: buttonIndex)))")
        print("Button Index : \(buttonIndex)")
        
        if buttonIndex == 0 { return }
        
        let imageController = UIImagePickerController()
        imageController.isEditing = false
        imageController.delegate = self;
        
        if( buttonIndex == 1){
            imageController.sourceType = UIImagePickerControllerSourceType.photoLibrary
        } else if(buttonIndex == 2){
            imageController.sourceType = UIImagePickerControllerSourceType.camera
            imageController.showsCameraControls = true
        } else {
            imageController.sourceType = UIImagePickerControllerSourceType.camera
            imageController.mediaTypes = [kUTTypeMovie as String]
            imageController.allowsEditing = false
            imageController.showsCameraControls = true
        }
        
        self.present(imageController, animated: true, completion: nil)
    }

    // MARK: - LimCameraImagePickerDelegate Methods
    
    func donePicking(picker: LimCameraImagePicker, didPickedUrls: [String]) {
        DispatchQueue.main.async {
            // update some UI
            self.cleanProcessOnPicking()

        }
    }
    
    func cleanProcessOnPicking() {
        self.navigationController!.popViewController(animated: true)
    }
    
    func cancelPicking(picker: LimCameraImagePicker) {
        self.navigationController!.popToViewController(self, animated: true)
    }

}

