//
//  WDImagePicker.swift
//  WDImagePicker
//
//  Created by Wu Di on 27/8/15.
//  Copyright (c) 2015 Wu Di. All rights reserved.
//

import UIKit

public enum WDImagePickerAspectRatioPreset {
    case presetSquare
    case preset6x1
}

@objc public protocol WDImagePickerDelegate {
    @objc optional func imagePicker(_ imagePicker: WDImagePicker, pickedImage: UIImage)
    @objc optional func imagePickerDidCancel(_ imagePicker: WDImagePicker)
}

@objc open class WDImagePicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, WDImageCropControllerDelegate {

    open var delegate: WDImagePickerDelegate?

    ///A choice from one of the pre-defined aspect ratio presets
    open var aspectRatioPreset: WDImagePickerAspectRatioPreset = .presetSquare
    open var cancelButtonTitle: String?
    open var chooseButtonTitle: String?
    open var useButtonTitle: String?
    open var resizableCropArea = false

    private var _imagePickerController: UIImagePickerController!

    open var imagePickerController: UIImagePickerController {
        return _imagePickerController
    }
    
    override public init() {
        super.init()

        _imagePickerController = UIImagePickerController()
        _imagePickerController.delegate = self
        _imagePickerController.sourceType = .photoLibrary
    }

    private func hideController() {
        self._imagePickerController.dismiss(animated: true, completion: nil)
    }

    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if self.delegate?.imagePickerDidCancel != nil {
            self.delegate?.imagePickerDidCancel!(self)
        } else {
            self.hideController()
        }
    }

    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey : Any]) {
        let cropController = WDImageCropViewController()    
        cropController.sourceImage = info[.originalImage] as? UIImage
        cropController.resizableCropArea = self.resizableCropArea
        cropController.aspectRatioPreset = self.aspectRatioPreset
        cropController.cancelButtonTitle = self.cancelButtonTitle
        cropController.chooseButtonTitle = self.chooseButtonTitle
        cropController.useButtonTitle = self.useButtonTitle
        cropController.delegate = self

        if UIDevice.current.userInterfaceIdiom == .pad {
            cropController.modalPresentationStyle = .pageSheet
            cropController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            picker.present(UINavigationController(rootViewController: cropController), animated: true, completion: nil)
        } else {
            picker.pushViewController(cropController, animated: true)
        }
    }

    func imageCropController(_ imageCropController: WDImageCropViewController, didFinishWithCroppedImage croppedImage: UIImage) {
        self.delegate?.imagePicker?(self, pickedImage: croppedImage)
    }

    func imageCropControllerDidCancel(_ imageCropController: WDImageCropViewController) {
        if _imagePickerController.sourceType == .photoLibrary && UIDevice.current.userInterfaceIdiom != .pad {
            imageCropController.navigationController?.popViewController(animated: true)
        } else {
            imageCropController.dismiss(animated: true, completion: nil)
        }
    }
}
