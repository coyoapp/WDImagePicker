//
//  WDImageCropView.swift
//  WDImagePicker
//
//  Created by Wu Di on 27/8/15.
//  Copyright (c) 2015 Wu Di. All rights reserved.
//

import UIKit
import QuartzCore

private class ScrollView: UIScrollView {
    fileprivate override func layoutSubviews() {
        super.layoutSubviews()

        if let zoomView = self.delegate?.viewForZooming?(in: self) {
            let boundsSize = self.bounds.size
            var frameToCenter = zoomView.frame

            // center horizontally
            if frameToCenter.size.width < boundsSize.width {
                frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
            } else {
                frameToCenter.origin.x = 0
            }

            // center vertically
            if frameToCenter.size.height < boundsSize.height {
                frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
            } else {
                frameToCenter.origin.y = 0
            }

            zoomView.frame = frameToCenter
        }
    }
}

internal class WDImageCropView: UIView, UIScrollViewDelegate {
    var resizableCropArea = false

    fileprivate var scrollView: UIScrollView!
    fileprivate var imageView: UIImageView!
    fileprivate var cropOverlayView: WDImageCropOverlayView!
    fileprivate var xOffset: CGFloat!
    fileprivate var yOffset: CGFloat!

    fileprivate static func scaleRect(_ rect: CGRect, scale: CGFloat) -> CGRect {
        return CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale)
    }

    var imageToCrop: UIImage? {
        get {
            return self.imageView.image
        }
        set {
            self.imageView.image = newValue
        }
    }

    var cropSize: CGSize {
        get {
            return self.cropOverlayView.cropSize
        }
        set {
            if let view = self.cropOverlayView {
                view.cropSize = newValue
            } else {
                if self.resizableCropArea {
                    self.cropOverlayView = WDResizableCropOverlayView(frame: self.bounds,
                        initialContentSize: CGSize(width: newValue.width, height: newValue.height))
                } else {
                    self.cropOverlayView = WDImageCropOverlayView(frame: self.bounds)
                }
                self.cropOverlayView.cropSize = newValue
                self.addSubview(self.cropOverlayView)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.black
        self.scrollView = ScrollView(frame: frame)
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.delegate = self
        self.scrollView.clipsToBounds = false
        self.scrollView.decelerationRate = UIScrollView.DecelerationRate.normal
        self.scrollView.backgroundColor = UIColor.clear
        self.scrollView.alwaysBounceHorizontal = true
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.contentInsetAdjustmentBehavior = .automatic
        self.addSubview(self.scrollView)

        self.imageView = UIImageView(frame: .zero)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.backgroundColor = UIColor.black
        self.imageView.isUserInteractionEnabled = true
        self.scrollView.addSubview(self.imageView)

        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 20
        self.scrollView.setZoomScale(1, animated: true)
        self.scrollView.isScrollEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !resizableCropArea {
            return self.scrollView
        }

        let resizableCropView = cropOverlayView as! WDResizableCropOverlayView
        let outerFrame = resizableCropView.cropBorderView.frame.insetBy(dx: -10, dy: -10)

        if outerFrame.contains(point) {
            if resizableCropView.cropBorderView.frame.size.width < 60 ||
                resizableCropView.cropBorderView.frame.size.height < 60 {
                    return super.hitTest(point, with: event)
            }

            let innerTouchFrame = resizableCropView.cropBorderView.frame.insetBy(dx: 30, dy: 30)
            if innerTouchFrame.contains(point) {
                return self.scrollView
            }

            let outBorderTouchFrame = resizableCropView.cropBorderView.frame.insetBy(dx: -10, dy: -10)
            if outBorderTouchFrame.contains(point) {
                return super.hitTest(point, with: event)
            }

            return super.hitTest(point, with: event)
        }

        return self.scrollView
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let toolbarSize = CGFloat(54)

        let height = self.imageToCrop!.size.height
        let width = self.imageToCrop!.size.width

        var factor: CGFloat = 0
        var factoredHeight: CGFloat = 0
        var factoredWidth: CGFloat = 0

        factor = width / cropSize.width
        factoredWidth = cropSize.width
        factoredHeight =  height / factor

        self.cropOverlayView.frame = self.bounds
        self.imageView.frame = CGRect(x: 0, y: floor((cropSize.height - factoredHeight) * 0.5),
            width: factoredWidth, height: factoredHeight)
        self.xOffset = floor((self.bounds.width - cropSize.width) * 0.5)
        self.yOffset = floor((self.bounds.height - toolbarSize - cropSize.height) * 0.5)
        self.scrollView.frame = CGRect(x: xOffset, y: yOffset, width: cropSize.width, height: cropSize.height)
        self.scrollView.contentSize = self.imageView.frame.size

        if cropSize.height < factoredHeight {
            self.scrollView.setContentOffset(CGPoint(x: 0, y: -floor((cropSize.height - factoredHeight) * 0.5)), animated: false)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    func croppedImage() -> UIImage? {
        // Calculate rect that needs to be cropped
        var visibleRect = resizableCropArea ?
            calcVisibleRectForResizeableCropArea() : calcVisibleRectForCropArea()

        // transform visible rect to image orientation
        let rectTransform = orientationTransformedRectOfImage(imageToCrop!)
        visibleRect = visibleRect.applying(rectTransform);

        // finally crop image
        guard let imageRef = imageToCrop!.cgImage?.cropping(to: visibleRect) else {
            return nil
        }

        let result = UIImage(cgImage: imageRef, scale: imageToCrop!.scale,
            orientation: imageToCrop!.imageOrientation)
        return result
    }

    fileprivate func calcVisibleRectForResizeableCropArea() -> CGRect {
        let resizableView = cropOverlayView as! WDResizableCropOverlayView

        // first of all, get the size scale by taking a look at the real image dimensions. Here it 
        // doesn't matter if you take the width or the hight of the image, because it will always 
        // be scaled in the exact same proportion of the real image
        var sizeScale = self.imageView.image!.size.width / self.imageView.frame.size.width
        sizeScale *= self.scrollView.zoomScale

        // then get the postion of the cropping rect inside the image
        var visibleRect = resizableView.contentView.convert(resizableView.contentView.bounds,
            to: imageView)
        visibleRect = WDImageCropView.scaleRect(visibleRect, scale: sizeScale)

        return visibleRect
    }

    fileprivate func calcVisibleRectForCropArea() -> CGRect {
        // scaled width/height in regards of real width to crop width
        let scaleWidth = imageToCrop!.size.width / cropSize.width
        let scaleHeight = imageToCrop!.size.height / cropSize.height
        var scale: CGFloat = 0

        if cropSize.width > cropSize.height { // 6x1 Crop
            scale = min(scaleWidth, scaleHeight)
        } else { // Square crop
            scale = imageToCrop!.size.width < imageToCrop!.size.height ?
                min(scaleWidth, scaleHeight) :
                max(scaleWidth, scaleHeight)
        }

        // extract visible rect from scrollview and scale it
        var visibleRect = scrollView.convert(scrollView.bounds, to:imageView)
        visibleRect = WDImageCropView.scaleRect(visibleRect, scale: scale)

        return visibleRect
    }

    fileprivate func orientationTransformedRectOfImage(_ image: UIImage) -> CGAffineTransform {
        var rectTransform: CGAffineTransform!

        switch image.imageOrientation {
        case .left:
            rectTransform = CGAffineTransform(rotationAngle: CGFloat(Float.pi/2)).translatedBy(x: 0, y: -image.size.height)
        case .right:
            rectTransform = CGAffineTransform(rotationAngle: CGFloat(-Float.pi/2)).translatedBy(x: -image.size.width, y: 0)
        case .down:
            rectTransform = CGAffineTransform(rotationAngle: CGFloat(-Float.pi)).translatedBy(x: -image.size.width, y: -image.size.height)
        default:
            rectTransform = CGAffineTransform.identity
        }

        return rectTransform.scaledBy(x: image.scale, y: image.scale)
    }
}
