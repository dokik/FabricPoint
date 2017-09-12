//
//  CameraViewController.swift
//  FabricPoint
//
//  Created by doki on 2017/07/18.
//  Copyright © 2017年 RDG. All rights reserved.
//

import UIKit
import AVFoundation

//------------------------------------//
//カメラ画面（本を借りる/返す）
//------------------------------------//
class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var delegate: ViewControllerDelegate!
    
    //Backボタン押下
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet var captureView: UIView!
    
    private lazy var captureSession: AVCaptureSession = AVCaptureSession()
    private lazy var captureDevice: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    private lazy var capturePreviewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        return layer!
    }()
    
    private var captureInput: AVCaptureInput? = nil
    private lazy var captureOutput: AVCaptureMetadataOutput = {
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        return output
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBarcodeCapture()
        
        let underView = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.size.width, height:self.view.frame.size.height/8)))
        underView.center = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-underView.frame.size.height/2)
        underView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        self.captureView.addSubview(underView)
        
        let closeButton = UIButton()
        closeButton.setTitle("閉じる", for: .normal)
        closeButton.setTitleColor(UIColor.white, for: .normal)
        closeButton.sizeToFit()
        closeButton.center = CGPoint(x: underView.frame.size.width/2, y: underView.frame.size.height/2)
//        closeButton.addTarget(self, action: #selector(tapedCloseButton(_:)), forControlEvents: .TouchUpInside)
        closeButton.addTarget(self, action: #selector(CameraViewController.back(_:)), for: .touchUpInside)
        underView.addSubview(closeButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        capturePreviewLayer.frame = self.captureView?.bounds ?? CGRect.zero
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - private
    private func setupBarcodeCapture() {
        do {
            captureInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureInput)
            captureSession.addOutput(captureOutput)
            captureOutput.metadataObjectTypes = captureOutput.availableMetadataObjectTypes
            capturePreviewLayer.frame = self.captureView?.bounds ?? CGRect.zero
            capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            captureView?.layer.addSublayer(capturePreviewLayer)
            captureSession.startRunning()
        } catch let error as NSError {
            print(error)
        }
    }
    

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        self.captureSession.stopRunning()
        guard let objects = metadataObjects as? [AVMetadataObject] else { return }
        var detectionString: String? = nil
        let barcodeTypes = [AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeEAN13Code]
        
//        for metadataObject in objects {
//            if let object = metadataObject as? AVMetadataMachineReadableCodeObject {
//                detectionString = object.stringValue
//            }
//            var text = ""
//            guard let value = detectionString else { continue }
//            text += "読み込んだ値:\t\(value)"
//            text += "\n"
//            print(text)
//            
//            delegate.getPoint(qrString: value)
//        }
        if let object = objects[0] as? AVMetadataMachineReadableCodeObject {
            detectionString = object.stringValue
        }
        var text = ""
        let value: String = detectionString!
        text += "読み込んだ値:\t\(value)"
        text += "\n"
        print(text)
        
        delegate.getPoint(qrString: value)
        
        self.dismiss(animated: true, completion: nil)

    }
    
}
