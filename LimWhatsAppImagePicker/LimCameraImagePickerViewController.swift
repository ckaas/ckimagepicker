//
//  LimCameraImagePickerViewController.swift
//
//  Created by super on 2/23/15.
//  Copyright (c) 2015 super. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import MobileCoreServices
import QuartzCore

class LimCameraImagePicker: UIViewController,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDataSource,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{

    var pickerController:UIImagePickerController?
    var sourceType : UIImagePickerController.SourceType?
    var loadedImages: [UIImage] = []
    
    var selectedIndex : Int = -1
    
//    var loadingNotification : MBProgressHUD?

    @IBOutlet var mainBgView: UIView!
    @IBOutlet var btnRemover: UIButton!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var bgView: UIView!
    @IBOutlet var collectionView: UICollectionView!
    
    weak var delegate: LimCameraImagePickerDelegate?
    
    //AWS UPLOAD
    var uploadFileURL: URL?
    var tempIndex : Int = 0
    var tempImage: UIImage?;
    
    var isuploading : Bool = false
    var loadedUrls : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    
    }
    
    override func loadView() {
        super.loadView()
        
        collectionView.register(LimCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        self.automaticallyAdjustsScrollViewInsets = false
        
        let nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.black
        
        let gradient : CAGradientLayer = CAGradientLayer()
        gradient.frame = bgView.bounds
        let cor1 = UIColor.lightGray.cgColor
        let cor2 = UIColor.darkGray.cgColor
        let arrayColors = [cor1, cor2]
        gradient.colors = arrayColors
        bgView.layer.insertSublayer(gradient, at: 0)
        
        // Background view for images collection
        bgView.layer.shadowColor = UIColor.black.cgColor;
        bgView.layer.shadowRadius = 3.0
        bgView.layer.shadowOpacity = 0.15
        
        // Customize default ImageView
        imageView.layer.masksToBounds = true;
        imageView.layer.shadowColor = UIColor.black.cgColor;
        imageView.layer.shadowOpacity = 0.3;
        imageView.layer.shadowRadius = 6.0;
        
        if sourceType == nil {
            // Picker Controller Init
            pickerController =  UIImagePickerController()
            pickerController!.delegate = self
            pickerController!.sourceType = UIImagePickerControllerSourceType.photoLibrary
            sourceType = UIImagePickerControllerSourceType.photoLibrary
        }
        
        // Btn Remover
        btnRemover.backgroundColor = UIColor.white
        btnRemover.layer.cornerRadius = 15.0;

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set buttons for navigation
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPicker))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePicker))
        
        navigationController?.isNavigationBarHidden = false
        
        navigationItem.setLeftBarButton(cancelButton, animated: true)
        navigationItem.setRightBarButton(doneButton, animated: true)
        
        collectionView.reloadData()
        selectLastImage()
        setCurrentImage()
        
    }
    
    @IBAction func removeImage(sender: AnyObject) {
        if isuploading {return }
        loadedImages.remove(at: selectedIndex)
        collectionView.reloadData()
        
        if loadedImages.count > 0 {
            selectLastImage()
            setCurrentImage()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - uiCollectionView Datasource Methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loadedImages.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! LimCollectionViewCell
        
        if indexPath.row == loadedImages.count {
            cell.styleAddButton()
            cell.imageView.image = nil;
        }else{
            cell.styleImage()
            cell.imageView.image =    loadedImages[indexPath.row] as UIImage
        }

        return cell
    }
    
    // MARK: - uiCollectionView Datasource Methods
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row == loadedImages.count {
            self.presentCameraView()
//            // TODO: fix later!
//            let delayTime = DispatchTime.now() + 0.1
//            DispatchQueue.main.asyncAfter(deadline: delayTime) {
//                self.presentCameraView()
//            }
        }else{
            selectedIndex = indexPath.row;
            setCurrentImage()
        }
    }
    
    func presentCameraView () {
        let newpicker =  UIImagePickerController()
        newpicker.delegate = self
        newpicker.sourceType = sourceType!
        newpicker.isEditing = false
        
        if (newpicker.sourceType == UIImagePickerControllerSourceType.camera) {
            newpicker.showsCameraControls = true
        }
        
        self.present(newpicker, animated: true, completion: nil)
    }
    
    // MARK: - imagePickerController and actionsheet Delegate Methods
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: {})
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        let mediaType = info[UIImagePickerControllerMediaType] as! CFString
        
        if mediaType == kUTTypeImage {
            
            let originalImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage
            let imageToUse = editedImage != nil ? editedImage : originalImage
            
            loadedImages.append(imageToUse!)
            picker.dismiss(animated: true, completion: nil)
            
        } else {
          /*  let tempImage = info[UIImagePickerControllerMediaURL] as NSURL!
            
            let pathString = tempImage.relativePath
            self.dismissViewControllerAnimated(true, completion: {})
            
            UISaveVideoAtPathToSavedPhotosAlbum(pathString, self, nil, nil)
            println("Video Taken!!!!"); */
            
            picker.dismiss(animated: true, completion: {})
        }
    }
    
    // MARK:- UI navigation bar delegate
    
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
            
        navigationController.navigationBar.barStyle = UIBarStyle.black
    }
    
    
    //MARK: - Main Logic
    
    func cancelPicker () {
        if isuploading {return}
        loadedImages.removeAll()
        self.delegate?.cancelPicking(picker: self)
    }
    
    func donePicker () {
        if isuploading {return}
        
        loadedUrls.removeAll()
        
/*        if loadingNotification == nil {
            loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            loadingNotification!.mode = MBProgressHUDModeIndeterminate
        }*/
        doUpload()
    }
    
    func doUpload () {

        isuploading = true
        
//        loadingNotification!.labelText = "Uploading \(tempIndex+1) of \(loadedImages.count)"
        
        let date = NSDate()
        let timestamp = NSInteger(date.timeIntervalSince1970)
        let S3UploadKeyName = String(timestamp)
        
        print(S3UploadKeyName)
        
        //Create a test file in the temporary directory
        self.uploadFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + S3UploadKeyName)
        guard let uploadURL = self.uploadFileURL else { return }
        print(uploadURL.absoluteString)
        
        tempImage = loadedImages[tempIndex]
        let data = UIImageJPEGRepresentation(tempImage!, 0.5)
        
        if FileManager.default.fileExists(atPath: uploadURL.absoluteString) {
            try? FileManager.default.removeItem(at: self.uploadFileURL!)
        }

        try? data?.write(to: uploadURL, options: [.atomic])

/*        let uploadRequest1 : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        
        uploadRequest1.bucket = S3BucketName
        uploadRequest1.key =  "Uploads/" + S3UploadKeyName
        uploadRequest1.body = self.uploadFileURL
        uploadRequest1.ACL = AWSS3ObjectCannedACL.PublicRead
        
        let task = transferManager.upload(uploadRequest1)
        
        task.continueWithBlock { (task) -> AnyObject! in
            
            self.isuploading = false

            if task.error != nil {
                println("Error: \(task.error)")
                self.loadedImages.removeAll()
//                MBProgressHUD.hideAllHUDsForView(self.view, animated: false)
                
                self.delegate?.cancelPicking(self)
            } else {
                ++self.tempIndex
                var url = "--your url - \(S3UploadKeyName)"
                self.loadedUrls.append(url)
                
                if self.tempIndex == self.loadedImages.count {
//                    MBProgressHUD.hideAllHUDsForView(self.view, animated: false)
//                    self.loadingNotification = nil
                    
                    self.loadedImages.removeAll()
                    println("Upload successful")
                    self.delegate?.donePicking(self, didPickedUrls: self.loadedUrls)
                } else {
                    println("Moving to next upload")
                    self.doUpload()
                }
                
            }
            return nil
        }

*/
        //remove this code when you activate above commented code
        self.delegate?.donePicking(picker: self, didPickedUrls: self.loadedUrls)

    }
    
    internal func addImage (image:UIImage!)  {
        loadedImages.append(image)
    }
    
    func selectLastImage () {
        if loadedImages.count > 0  {
            selectedIndex = loadedImages.count-1 ;
            collectionView.selectItem(at: IndexPath(item: selectedIndex, section: 0), animated: true, scrollPosition: UICollectionViewScrollPosition.right)
        } else {
            selectedIndex = -1;
        }
    }
    
    func setCurrentImage () {
        if selectedIndex == -1 {  return }
        
        imageView.image = loadedImages[selectedIndex]
        let height = imageView.image!.size.height * imageView.frame.size.width / imageView.image!.size.width
        imageView.bounds = CGRect(x: imageView.bounds.origin.x, y: imageView.bounds.origin.y, width: imageView.bounds.size.width, height: height);
        
        // Positioning button x
        let btX = (imageView.center.x - (imageView.frame.size.width/2)) - 15;
        let btY = (imageView.center.y - (imageView.frame.size.height/2)) - 15;
        btnRemover.frame = CGRect(x: btX, y: btY, width: btnRemover.frame.size.width, height: btnRemover.frame.size.height);
        
        mainBgView.bringSubview(toFront: btnRemover)
    }
    
    internal func setSourceType (type: UIImagePickerControllerSourceType) {
        sourceType = type
        
        pickerController =  UIImagePickerController()
        pickerController!.delegate = self
        pickerController!.sourceType = type
        
        if type == UIImagePickerControllerSourceType.camera {
            pickerController!.showsCameraControls = true
        }
    }
}

protocol LimCameraImagePickerDelegate: class {
    func donePicking(picker: LimCameraImagePicker, didPickedUrls: [String])
    func cancelPicking(picker: LimCameraImagePicker)
}
