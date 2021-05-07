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
}

internal class WDImageCropViewController: UIViewController {
    var sourceImage: UIImage!
    var delegate: WDImageCropControllerDelegate?
    var aspectRatioPreset: WDImagePickerAspectRatioPreset!
    var resizableCropArea = false
    var ipadTitle: String?

    var cancelButtonTitle: String?

    /// For iphone
    var chooseButtonTitle: String?

    /// For ipad
    var useButtonTitle: String?

    private var croppedImage: UIImage!
    private var imageCropView: WDImageCropView!
    private var toolbar: UIToolbar!
    private var useButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.ipadTitle ?? "Choose Photo"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.setupCropView()

        if UIDevice.current.userInterfaceIdiom == .phone {
            self.navigationController?.isNavigationBarHidden = true
            self.setupToolbar()
        } else {
            self.navigationController?.isNavigationBarHidden = false
            self.setupNavigationBar()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        self.imageCropView.frame = self.view.bounds

        let safeFrame = self.view.safeAreaLayoutGuide.layoutFrame
        let bottomSafeAreaHeight = self.view.frame.maxY - safeFrame.maxY
        self.toolbar?.frame = CGRect(x: 0, y: self.view.bounds.height - bottomSafeAreaHeight  - 54,
                                    width: self.view.frame.size.width, height: 54)
    }

    @objc func actionCancel(_ sender: AnyObject) {

        if UIDevice.current.userInterfaceIdiom == .pad {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc func actionUse(_ sender: AnyObject) {
        croppedImage = self.imageCropView.croppedImage()
        self.delegate?.imageCropController(self, didFinishWithCroppedImage: croppedImage)
    }

    private func setupNavigationBar() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.cancelButtonTitle ?? "Cancel",
                                                                style: .plain,
                                                                target: self,
                                                                action:  #selector(self.actionCancel))

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.useButtonTitle ?? "Use",
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(self.actionUse))
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
        if UIDevice.current.userInterfaceIdiom == .phone {

            self.toolbar = UIToolbar(frame: CGRect(x: 0, y: -54, width: self.view.frame.size.width, height: 54))
            self.toolbar.isTranslucent = true
            self.toolbar.barStyle = .black

            let info = UILabel(frame: CGRect.zero)
            info.text = ""
            info.textColor = UIColor(red: 0.173, green: 0.173, blue: 0.173, alpha: 1)
            info.backgroundColor = UIColor.clear
            info.shadowColor = UIColor(red: 0.827, green: 0.731, blue: 0.839, alpha: 1)
            info.shadowOffset = CGSize(width: 0, height: 1)
            info.font = UIFont.boldSystemFont(ofSize: 18)
            info.sizeToFit()

            let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let label = UIBarButtonItem(customView: info)

            let cancelButton = UIBarButtonItem(title: cancelButtonTitle ?? "Cancel", style: .plain, target: self, action:  #selector(actionCancel))
            cancelButton.tintColor = .white

            let chooseButton = UIBarButtonItem(title: chooseButtonTitle ?? "Choose", style: .plain, target: self, action:  #selector(actionUse))
            chooseButton.tintColor = .white

            self.toolbar.setItems([cancelButton, flex, label, flex, chooseButton], animated: false)
            self.toolbar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.toolbar.autoresizesSubviews = true
            self.toolbar.sizeToFit()
            self.view.addSubview(self.toolbar)
        }
    }
}
