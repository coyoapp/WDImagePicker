//
//  WDImageCropViewController.swift
//  WDImagePicker
//
//  Created by Wu Di on 27/8/15.
//  Copyright (c) 2015 Wu Di. All rights reserved.
//

import UIKit
import CoreGraphics

internal protocol WDImageCropControllerDelegate {
    func imageCropController(_ imageCropController: WDImageCropViewController, didFinishWithCroppedImage croppedImage: UIImage)
    func imageCropControllerDidCancel(_ imageCropController: WDImageCropViewController)
}

internal class WDImageCropViewController: UIViewController {
    var sourceImage: UIImage!
    var delegate: WDImageCropControllerDelegate?
    var aspectRatioPreset: WDImagePickerAspectRatioPreset!
    var resizableCropArea = false

    var cancelButtonTitle: String?
    var chooseButtonTitle: String?
    var useButtonTitle: String?

    private var croppedImage: UIImage?
    private var imageCropView: WDImageCropView!
    private var toolbar: UIToolbar!
    private var useButton: UIButton!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.setupCropView()

        self.navigationController?.isNavigationBarHidden = true
        self.setupToolbar()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        self.imageCropView.frame = self.view.bounds
    }

    @objc func actionCancel(_ sender: AnyObject) {
        self.delegate?.imageCropControllerDidCancel(self)
    }

    @objc func actionUse(_ sender: AnyObject) {
        guard let croppedImage = self.imageCropView.croppedImage() else {
            NSLog("Cropped Image not found.")
            return
        }
        self.delegate?.imageCropController(self, didFinishWithCroppedImage: croppedImage)
    }

    private func setupCropView() {
        self.imageCropView = WDImageCropView(frame: self.view.bounds)
        self.imageCropView.imageToCrop = sourceImage
        self.imageCropView.resizableCropArea = self.resizableCropArea
        self.imageCropView.cropSize = estimatedCropSize()
        self.view.addSubview(self.imageCropView)
    }

    private func estimatedCropSize() -> CGSize {

        let viewWidth = self.view.bounds.width

        switch self.aspectRatioPreset {
        case .preset6x1:
            return CGSize(width: viewWidth, height: viewWidth / 6)
        default:
            return CGSize(width: viewWidth, height: viewWidth)
        }
    }

    private func toolbarBackgroundImage() -> UIImage {
        let components: [CGFloat] = [1, 1, 1, 1, 123.0 / 255.0, 125.0 / 255.0, 132.0 / 255.0, 1]

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 320, height: 54), true, 0)

        let context = UIGraphicsGetCurrentContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: nil, count: 2)

        context?.drawLinearGradient(gradient!, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 54), options: [])

        let viewImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return viewImage!
    }

    private func setupToolbar() {
        self.toolbar = UIToolbar(frame: CGRect(x: 0, y: -54, width: self.view.frame.size.width, height: 54))
        self.toolbar.isTranslucent = true
        self.toolbar.barStyle = .black

        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let cancelButton = UIBarButtonItem(title: cancelButtonTitle, style: .plain, target: self, action: #selector(actionCancel(_:)))
        cancelButton.tintColor = .white

        let chooseButton = UIBarButtonItem(title: chooseButtonTitle, style: .plain, target: self, action: #selector(actionUse(_:)))
        chooseButton.tintColor = .white

        self.toolbar.setItems([cancelButton, flex, chooseButton], animated: false)
        self.view.addSubview(self.toolbar)
        
        self.toolbar.translatesAutoresizingMaskIntoConstraints = false
        self.toolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.toolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.toolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        self.toolbar.heightAnchor.constraint(equalToConstant: 54).isActive = true
    }
}
