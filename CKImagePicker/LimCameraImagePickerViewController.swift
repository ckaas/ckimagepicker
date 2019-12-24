//
//  CKImagePickerViewController.swift
//

import Foundation
import UIKit
import MediaPlayer
import MobileCoreServices
import QuartzCore

fileprivate let nothingSelected: Int = -1

class CKImagePickerViewController: UIViewController,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDataSource,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{
    var pickerController:UIImagePickerController?
    var sourceType : UIImagePickerController.SourceType?
    var loadedImages = [UIImage]()
    
    var selectedIndex : Int = nothingSelected
    
    @IBOutlet var mainBgView: UIView!
    @IBOutlet var btnRemover: UIButton!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var bgView: UIView!
    @IBOutlet var collectionView: UICollectionView!
    
    weak var delegate: CKImagePickerDelegate?

    static func ckImagePickerViewController() -> CKImagePickerViewController {
        let storyboard = UIStoryboard(name: "CKImagePickerViewController", bundle: nil)
        guard let ckImagePickerViewController = storyboard.instantiateViewController(identifier: "CKImagePickerViewController") as? CKImagePickerViewController
            else {
                fatalError("Cannot create CKImagePickerViewContoller from Storyboard!")
        }
        return ckImagePickerViewController
    }

    static func ckImagePickerViewControllerWrappedInNavigationController() -> (UINavigationController, CKImagePickerViewController) {
        let ckImagePickerViewController = CKImagePickerViewController.ckImagePickerViewController()
        let navigationController = UINavigationController(rootViewController: ckImagePickerViewController)
        navigationController.navigationBar.barStyle = UIBarStyle.black

        return (navigationController, ckImagePickerViewController)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.

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
            pickerController!.sourceType = UIImagePickerController.SourceType.photoLibrary
            sourceType = UIImagePickerController.SourceType.photoLibrary
        }

        // Btn Remover
//        btnRemover.backgroundColor = UIColor.lightGray
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // when we have no images captured yet, we immediatly present the imagepicker
        if loadedImages.count == 0 {
            presentPickerViewController()
        }
    }
    
    @IBAction func removeImage(sender: AnyObject) {
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
        // determine collectionView celltype - last one is always the add button
        let isAddButtonCell = indexPath.row == loadedImages.count

        let cellIdentifier = isAddButtonCell ? "CellButton" : "Cell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! CKCollectionViewCell
        
        if isAddButtonCell {
            cell.styleAddButton()
        }else{
            cell.style(image: loadedImages[indexPath.row])
        }

        return cell
    }
    
    // MARK: - uiCollectionView Datasource Methods
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row == loadedImages.count {
            self.presentPickerViewController()
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
    
    func presentPickerViewController () {
        let newpicker =  UIImagePickerController()
        newpicker.delegate = self
        newpicker.sourceType = sourceType!
        newpicker.isEditing = false
        
        if (newpicker.sourceType == UIImagePickerController.SourceType.camera) {
            newpicker.showsCameraControls = true
        }
        
        self.present(newpicker, animated: true, completion: nil)
    }
    
    // MARK: - imagePickerController and actionsheet Delegate Methods
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: {})
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let mediaType = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaType)] as? String,
            mediaType == kUTTypeImage as String {
            let originalImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
            let editedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage
            let imageToUse = editedImage != nil ? editedImage : originalImage
            
            addImage(image: imageToUse!)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK:- UI navigation bar delegate
    
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
            
        navigationController.navigationBar.barStyle = UIBarStyle.black
    }
    
    
    //MARK: - Main Logic
    
    @objc func cancelPicker () {
        loadedImages.removeAll()
        self.delegate?.ckImagePickerViewControllerDidCancel(self)
    }
    
    @objc func donePicker () {
        self.delegate?.ckImagePickerViewController(self, didFinishPickingWith: self.loadedImages)
    }
    
    fileprivate func addImage (image:UIImage!)  {
        loadedImages.append(image)
        collectionView?.reloadData()
    }
    
    func selectLastImage () {
        if loadedImages.count > 0  {
            selectedIndex = loadedImages.count - 1 ;
            collectionView.selectItem(at: IndexPath(item: selectedIndex, section: 0), animated: true, scrollPosition: UICollectionView.ScrollPosition.right)
        } else {
            selectedIndex = nothingSelected;
            btnRemover.isHidden = true
        }
    }
    
    func setCurrentImage () {
        if selectedIndex == nothingSelected { return }
        
        imageView.image = loadedImages[selectedIndex]
        btnRemover.isHidden = false
    }
    
    internal func setSourceType (type: UIImagePickerController.SourceType) {
        sourceType = type
        
        pickerController =  UIImagePickerController()
        pickerController!.delegate = self
        pickerController!.sourceType = type
        
        if type == UIImagePickerController.SourceType.camera {
            pickerController!.showsCameraControls = true
        }
    }
}

protocol CKImagePickerDelegate: class {
    func ckImagePickerViewController(_ picker: CKImagePickerViewController, didFinishPickingWith images: [UIImage])
    func ckImagePickerViewControllerDidCancel(_ picker: CKImagePickerViewController)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
