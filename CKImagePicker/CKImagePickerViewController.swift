//
//  CKImagePickerViewController.swift
//

import Foundation
import UIKit
import MediaPlayer
import MobileCoreServices
import QuartzCore

fileprivate let nothingSelected: Int = -1

@objc
protocol CKImagePickerDelegate: class {
    @objc
    func ckImagePickerViewController(_ picker: CKImagePickerViewController, didFinishPickingWith images: [UIImage])
    @objc
    func ckImagePickerViewControllerDidCancel(_ picker: CKImagePickerViewController)
}

@objc
class CKImagePickerViewController: UIViewController,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDataSource,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{
    fileprivate var pickerController:UIImagePickerController?
    fileprivate var loadedImages = [UIImage]()
    fileprivate var selectedIndex : Int = nothingSelected

    @IBOutlet var mainBgView: UIView!
    @IBOutlet var btnRemover: UIButton!
    @IBOutlet weak var buttonBackgroundView: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var bgView: UIView!
    @IBOutlet var collectionView: UICollectionView!

    @IBOutlet weak var buttonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonTopConstraint: NSLayoutConstraint!


    @objc
    var imagePickerControllerSourceType: Int {
        get {
            return self.sourceType.rawValue
        }
        set {
            self.sourceType = UIImagePickerController.SourceType(rawValue: newValue) ?? UIImagePickerController.SourceType.photoLibrary
        }
    }

    var sourceType : UIImagePickerController.SourceType = UIImagePickerController.SourceType.photoLibrary

    @objc
    var tintColor = UIButton.appearance().tintColor {
        didSet {
            self.btnRemover?.tintColor = tintColor
            collectionView?.reloadData()
        }
    }

    @objc
    weak var delegate: CKImagePickerDelegate?

    @objc
    static func ckImagePickerViewController() -> CKImagePickerViewController {
        let storyboard = UIStoryboard(name: "CKImagePickerViewController", bundle: nil)
        guard let ckImagePickerViewController = storyboard.instantiateViewController(withIdentifier: String(describing: self))  as? CKImagePickerViewController
            else {
                fatalError("Cannot create CKImagePickerViewContoller from Storyboard!")
        }
        return ckImagePickerViewController
    }

    @objc
    static func ckImagePickerViewControllerWrappedInNavigationController() -> UINavigationController {
        let ckImagePickerViewController = CKImagePickerViewController.ckImagePickerViewController()
        let navigationController = UINavigationController(rootViewController: ckImagePickerViewController)
        navigationController.navigationBar.barStyle = UIBarStyle.black

        return navigationController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.

        let nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.black

        // Customize default ImageView
        imageView.layer.masksToBounds = true;
        imageView.layer.shadowColor = UIColor.black.cgColor;
        imageView.layer.shadowOpacity = 0.3;
        imageView.layer.shadowRadius = 6.0;

        if pickerController == nil {
            // Picker Controller Init
            pickerController =  UIImagePickerController()
            pickerController!.delegate = self
            pickerController!.sourceType = UIImagePickerController.SourceType.photoLibrary
            sourceType = UIImagePickerController.SourceType.photoLibrary
        }

        // Btn Remover
        buttonBackgroundView.layer.cornerRadius = 5.0
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
        collectionView.deleteItems(at: [IndexPath(row: selectedIndex, section: 0)])

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
        cell.tintColor = tintColor
        
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
        }else{
            selectedIndex = indexPath.row;
            setCurrentImage()
        }
    }
    
    func presentPickerViewController () {
        let newpicker =  UIImagePickerController()
        newpicker.delegate = self
        newpicker.sourceType = sourceType
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
        selectLastImage()
        // run they selection later in runLoop
        DispatchQueue.main.async { [weak self] in
            self?.setCurrentImage()
        }
    }
    
    func selectLastImage () {
        if loadedImages.count > 0  {
            selectedIndex = loadedImages.count - 1 ;
        } else {
            selectedIndex = nothingSelected;
            btnRemover.isHidden = true
        }
    }
    
    func setCurrentImage () {
        if selectedIndex == nothingSelected { return }
        
        imageView.image = loadedImages[selectedIndex]
        collectionView.selectItem(at: IndexPath(row: selectedIndex, section: 0), animated: true, scrollPosition: .right)
        btnRemover.isHidden = false
//        let imageDrawnRect = self.imageView.contentClippingRect
//        buttonTopConstraint.constant = -44 - trunc(imageDrawnRect.origin.y)
//        buttonLeadingConstraint.constant = -44 - trunc(imageDrawnRect.origin.x)
//        view.layoutIfNeeded()
//        UIView.animate(withDuration: 0.3) { [weak self] in
//            self?.buttonTopConstraint.constant = -44 - trunc(imageDrawnRect.origin.y)
//            self?.buttonLeadingConstraint.constant = -44 - trunc(imageDrawnRect.origin.x)
//            self?.view.layoutIfNeeded()
//        }
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

fileprivate extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}
