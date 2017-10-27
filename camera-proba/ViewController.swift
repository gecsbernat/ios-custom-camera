//
//  ViewController.swift
//  camera-proba
//
//  Created by Bernát on 2017. 10. 24..
//  Copyright © 2017. Bernát. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, SFSpeechRecognizerDelegate {
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?
    var captureDevice:AVCaptureDevice?
    var cameraView: UIView?
    var movieFileOutput = AVCaptureMovieFileOutput()
    var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var isRecording = false
    var node: AVAudioInputNode?
    
    var Flabel: UILabel?
    var Fslider: UISlider?
    var Wlabel: UILabel?
    var Wslider: UISlider?
    var Zlabel: UILabel?
    var Zslider: UISlider?
    var RECORD_BUTTON: UIButton?
    var speechSwich: UISwitch?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        
        self.recordAndRecognizeSpeech()
        
        let windowXcenter = view.bounds.midX
        let width = view.bounds.width * 0.9
        let height = view.bounds.height
        let Cx = windowXcenter - (width/2)
        let Cy = height * 0.04
        
        //CAMERA UIVIEW
        cameraView = UIView(frame: CGRect(x: Cx, y: Cy, width: width, height: width))
        cameraView?.backgroundColor = UIColor.black
        self.view.addSubview(cameraView!)
        
        captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
    
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput?.isHighResolutionCaptureEnabled = true
            captureSession?.addOutput(capturePhotoOutput!)
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self as? AVCaptureMetadataOutputObjectsDelegate, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr,AVMetadataObject.ObjectType.face]
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = (cameraView?.layer.bounds)!
            cameraView?.layer.addSublayer(videoPreviewLayer!)
            captureSession?.startRunning()
        } catch {
            print(error)
            return
        }
        
        //SLIDER
        let Sy = (cameraView?.bounds.midY)!+((cameraView?.bounds.height)!/2)+80
        
        //FOCUS
        Flabel = UILabel(frame: CGRect(x: Cx-10, y: Sy, width: 100, height: 20))
        Flabel?.textAlignment = .left
        Flabel?.textColor = UIColor.white
        Flabel?.text = "F"
        self.view.addSubview(Flabel!)
        
        Fslider = UISlider(frame:CGRect(x: Cx+20, y: Sy, width: width-20, height: 20))
        Fslider?.minimumValue = 0
        Fslider?.maximumValue = 1
        Fslider?.isContinuous = true
        Fslider?.tintColor = UIColor.green
        Fslider?.addTarget(self, action: #selector(focus), for: .valueChanged)
        self.view.addSubview(Fslider!)
        
        //WB
        Wlabel = UILabel(frame: CGRect(x: Cx-10, y: Sy+40, width: 100, height: 20))
        Wlabel?.textAlignment = .left
        Wlabel?.textColor = UIColor.white
        Wlabel?.text = "WB"
        self.view.addSubview(Wlabel!)
        
        Wslider = UISlider(frame:CGRect(x: Cx+20, y: Sy+40, width: width-20, height: 20))
        Wslider?.minimumValue = 1000
        Wslider?.maximumValue = 12000
        Wslider?.isContinuous = true
        Wslider?.tintColor = UIColor.green
        Wslider?.addTarget(self, action: #selector(whitebalance), for: .valueChanged)
        self.view.addSubview(Wslider!)
        
        //ZOOM
        Zlabel = UILabel(frame: CGRect(x: Cx-10, y: Sy+80, width: 100, height: 20))
        Zlabel?.textAlignment = .left
        Zlabel?.textColor = UIColor.white
        Zlabel?.text = "Z"
        self.view.addSubview(Zlabel!)
        
        Zslider = UISlider(frame:CGRect(x: Cx+20, y: Sy+80, width: width-20, height: 20))
        Zslider?.minimumValue = 1
        Zslider?.maximumValue = (Float((captureDevice?.activeFormat.videoMaxZoomFactor)!))/12.0
        Zslider?.isContinuous = true
        Zslider?.tintColor = UIColor.green
        Zslider?.addTarget(self, action: #selector(zoom), for: .valueChanged)
        self.view.addSubview(Zslider!)
        
        //RECORD_BUTTON
        RECORD_BUTTON = UIButton(type: .custom)
        RECORD_BUTTON?.frame = CGRect(x: windowXcenter-40, y: Sy+130, width: 80, height: 80)
        RECORD_BUTTON?.layer.cornerRadius = 0.5 * (RECORD_BUTTON?.bounds.size.width)!
        RECORD_BUTTON?.clipsToBounds = true
        RECORD_BUTTON?.backgroundColor = UIColor.red
        RECORD_BUTTON?.addTarget(self, action: #selector(recordVideo), for: .touchUpInside)
        self.view.addSubview(RECORD_BUTTON!)
        
        //PHOTO_BUTTON
        let PHOTO_BUTTON = UIButton(type: .custom)
        PHOTO_BUTTON.frame = CGRect(x: windowXcenter-120, y: Sy+140, width: 60, height: 60)
        PHOTO_BUTTON.layer.cornerRadius = 0.5 * PHOTO_BUTTON.bounds.size.width
        PHOTO_BUTTON.clipsToBounds = true
        PHOTO_BUTTON.backgroundColor = UIColor.white
        PHOTO_BUTTON.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        self.view.addSubview(PHOTO_BUTTON)
        
        //BUTTON_3
        let button3 = UIButton(type: .custom)
        button3.frame = CGRect(x: windowXcenter+60, y: Sy+140, width: 60, height: 60)
        button3.clipsToBounds = true
        button3.setTitle("Kész", for: .normal)
        //button3.addTarget(self, action: #selector(thumbsUpButtonPressed), for: .touchUpInside)
        view.addSubview(button3)
        
        //Speech recognition
        let speech = UILabel(frame: CGRect(x: Cx+180, y: Sy-40, width: 150, height: 20))
        speech.textAlignment = .left
        speech.textColor = UIColor.white
        speech.text = "Hangvezérlés"
        self.view.addSubview(speech)
        
        speechSwich = UISwitch(frame:CGRect(x: Cx+300, y: Sy-45, width: 200, height: 200))
        speechSwich?.addTarget(self, action: #selector(speechSwichChange(_:)), for: .valueChanged)
        speechSwich?.setOn(false, animated: true)
        self.view.addSubview(speechSwich!)
        
        
        //AUTOSW
        let Alabel = UILabel(frame: CGRect(x: Cx-10, y: Sy-40, width: 100, height: 20))
        Alabel.textAlignment = .left
        Alabel.textColor = UIColor.white
        Alabel.text = "Auto"
        self.view.addSubview(Alabel)
        
        let autoSwitch = UISwitch(frame:CGRect(x: Cx+30, y: Sy-45, width: 200, height: 200))
        autoSwitch.addTarget(self, action: #selector(autoSwitchChange(_:)), for: .valueChanged)
        autoSwitch.setOn(true, animated: false)
        self.view.addSubview(autoSwitch)
        
        self.Fslider?.isEnabled = false
        self.Wslider?.isEnabled = false
        
    }
    
    func cancelRecording() {
        audioEngine.stop()
        let node = audioEngine.inputNode
            node.removeTap(onBus: 0)
        
        recognitionTask?.cancel()
    }
    
    func recordAndRecognizeSpeech() {
        self.node = self.audioEngine.inputNode
        let recordingFormat = node?.outputFormat(forBus: 0)
        node?.installTap(onBus: 0, bufferSize: 102400, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        
        //print(count)
        
            self.audioEngine.prepare()
        do {
            try self.audioEngine.start()
        } catch {
            self.sendAlert(message: "There has been an audio engine error.")
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(message: "Speech recognition is not supported for your current locale.")
            return
        }
        if !myRecognizer.isAvailable {
            self.sendAlert(message: "Speech recognition is not currently available. Check back at a later time.")
            // Recognizer is not available right now
            return
        }
        
        self.recognitionTask = self.speechRecognizer?.recognitionTask(with: self.request, resultHandler: { result, error in
            if let result = result {
                
                let bestString = result.bestTranscription.formattedString
                print(bestString)
                
                //var helperString: String
                var lastString: String = ""
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = bestString.substring(from: indexTo)
                }
                self.checkForColorsSaid(resultString: lastString)
            } else if let error = error {
                //self.sendAlert(message: "There has been a speech recognition error.")
                print("Error: \(error)")
            }
        })
        
    }
    
    func checkForColorsSaid(resultString: String) {
        if(self.speechSwich?.isOn)!{        switch resultString {
        case "start":
            if(!self.isRecording){
                self.recordVideo()
                DispatchQueue.main.async {
                    if(!self.isRecording){
                        self.RECORD_BUTTON?.layer.cornerRadius = 0.2 * (self.RECORD_BUTTON?.bounds.size.width)!
                    }
                }
            }
        case "Start":
            if(!self.isRecording){
                self.recordVideo()
                
                DispatchQueue.main.async {
                    if(!self.isRecording){
                        self.RECORD_BUTTON?.layer.cornerRadius = 0.2 * (self.RECORD_BUTTON?.bounds.size.width)!
                    }
                }
            }
        case "stop":
            if(self.isRecording){
                self.recordVideo()
                DispatchQueue.main.async {
                    if(!self.isRecording){
                        self.RECORD_BUTTON?.layer.cornerRadius = 0.5 * (self.RECORD_BUTTON?.bounds.size.width)!
                    }
                }
            }
        default: break
        }
    }
    }
    
    func sendAlert(message: String) {
        let alert = UIAlertController(title: "Speech Recognizer Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func takePhoto() {
        guard let capturePhotoOutput = self.capturePhotoOutput else { return }
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .off
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    @objc func recordVideo() {
        toggleMovieRecording()
        DispatchQueue.main.async {
            if(self.RECORD_BUTTON?.layer.cornerRadius == 0.5 * (self.RECORD_BUTTON?.bounds.size.width)! && !self.isRecording){
                self.RECORD_BUTTON?.layer.cornerRadius = 0.2 * (self.RECORD_BUTTON?.bounds.size.width)!
                self.isRecording = true
            } else {
                self.RECORD_BUTTON?.layer.cornerRadius = 0.5 * (self.RECORD_BUTTON?.bounds.size.width)!
                self.isRecording = false
            }
        }
    }
    
    // MARK: Recording Movies
    
   func toggleMovieRecording() {
        
        /*
         Disable the Camera button until recording finishes, and disable
         the Record button until recording starts or finishes.
         
         See the AVCaptureFileOutputRecordingDelegate methods.
     */
        /*if(self.RECORD_BUTTON?.layer.cornerRadius == 0.5 * (self.RECORD_BUTTON?.bounds.size.width)!){
            self.RECORD_BUTTON?.layer.cornerRadius = 0.2 * (self.RECORD_BUTTON?.bounds.size.width)!
        }*/
        /*
         Retrieve the video preview layer's video orientation on the main queue
         before entering the session queue. We do this to ensure UI elements are
         accessed on the main thread and session configuration is done on the session queue.
         */
        
        DispatchQueue.main.async {
            if !self.movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    /*
                     Setup background task.
                     This is needed because the `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)`
                     callback is not received until AVCam returns to the foreground unless you request background execution time.
                     This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
                     To conclude this background execution, endBackgroundTask(_:) is called in
                     `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)` after the recorded file has been saved.
                     */
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                
                // Update the orientation on the movie file output video connection before starting recording.
                let movieFileOutputConnection = self.movieFileOutput.connection(with: .video)

                
                let availableVideoCodecTypes = self.movieFileOutput.availableVideoCodecTypes
                
                if availableVideoCodecTypes.contains(.hevc) {
                    self.movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
                }
                
                // Start recording to a temporary file.
                let outputFileName = NSUUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                self.captureSession?.addOutput(self.movieFileOutput)
                self.movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            } else {
                self.movieFileOutput.stopRecording()
                self.captureSession?.removeOutput(self.movieFileOutput)
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Enable the Record button to let the user stop the recording.
        DispatchQueue.main.async {
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        /*
         Note that currentBackgroundRecordingID is used to end the background task
         associated with this recording. This allows a new recording to be started,
         associated with a new UIBackgroundTaskIdentifier, once the movie file output's
         `isRecording` property is back to false — which happens sometime after this method
         returns.
         
         Note: Since we use a unique file path for each recording, a new recording will
         not overwrite a recording currently being saved.
         */
        func cleanUp() {
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }
            
            if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskInvalid
                print("aaaaaaa")
                
                if currentBackgroundRecordingID != UIBackgroundTaskInvalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                }
            }
        }
        
        var success = true
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
        if success {
            // Check authorization status.
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // Save the movie file to the photo library and cleanup.
                    PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
                    }, completionHandler: { success, error in
                        if !success {
                            print("Could not save movie to photo library: \(String(describing: error))")
                        }
                        print(outputFileURL)
                        cleanUp()
                    }
                    )
                } else {
                    cleanUp()
                }
            }
        } else {
            cleanUp()
        }
        
        // Enable the Camera and Record buttons to let the user switch camera and start another recording.
            /*if(self.RECORD_BUTTON?.layer.cornerRadius == 0.2 * (self.RECORD_BUTTON?.bounds.size.width)!){
                self.RECORD_BUTTON?.layer.cornerRadius = 0.5 * (self.RECORD_BUTTON?.bounds.size.width)!

        }*/
        DispatchQueue.main.async {
            // Only enable the ability to change camera if the device has more than one camera.
        }
    }
    
    @objc func speechSwichChange(_ sender:UISwitch!){
        if (sender.isOn == true){
            print("UISwitch state is now ON")
        }
        else{
            print("UISwitch state is now Off")
        }
    }
    
    
    @objc func autoSwitchChange(_ sender:UISwitch!){
        if (sender.isOn == true){
            print("UISwitch state is now ON")
            self.Fslider?.isEnabled = false
            self.Wslider?.isEnabled = false
            enableContinuousAutoFocus()
            enableContinuousAutoExposure()
            enableContinuousAutoWhiteBalance()
            self.Fslider?.setValue(self.currentLensPosition()!, animated: true)
            self.Wslider?.setValue(self.currentTemperature()!, animated: true)
        }
        else{
            print("UISwitch state is now Off")
            self.Fslider?.isEnabled = true
            self.Wslider?.isEnabled = true
        }
    }
    
    @objc func focus(sender:UISlider!){
        self.lockFocusAtLensPosition(lensPosition: CGFloat(sender.value))
        print("Focus to: \(sender.value)")
    }
    
    @objc func zoom(sender:UISlider!){
        self.lockZoom(zoom: CGFloat(sender.value))
        print("Zoom to: \(sender.value)")
    }
    
    @objc func whitebalance(sender:UISlider!){
        self.setCustomWhiteBalanceWithTemperature(temperature: sender.value)
        print("WB to: \(sender.value)")
    }
    
    func lockFocusAtLensPosition(lensPosition:CGFloat) {
        performConfigurationOnCurrentCameraDevice { (currentDevice) -> Void in
            currentDevice.setFocusModeLocked(lensPosition: Float(lensPosition)) {
                (time:CMTime) -> Void in
                
            }
        }
    }
    
    func lockZoom(zoom:CGFloat) {
        performConfigurationOnCurrentCameraDevice { (currentDevice) -> Void in
            currentDevice.ramp(toVideoZoomFactor: zoom, withRate: 20.0)
        }
    }
    
    func enableContinuousAutoFocus() {
        performConfigurationOnCurrentCameraDevice { (currentDevice) -> Void in
            if currentDevice.isFocusModeSupported(.continuousAutoFocus) {
                currentDevice.focusMode = .continuousAutoFocus
            }
        }
    }
    
    func enableContinuousAutoExposure() {
        performConfigurationOnCurrentCameraDevice { (currentDevice) -> Void in
            if currentDevice.isExposureModeSupported(.continuousAutoExposure) {
                currentDevice.exposureMode = .continuousAutoExposure
            }
        }
    }
    
    func enableContinuousAutoWhiteBalance() {
        performConfigurationOnCurrentCameraDevice { (currentDevice) -> Void in
            if currentDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                currentDevice.whiteBalanceMode = .continuousAutoWhiteBalance
            }
        }
    }
    
    func currentLensPosition() -> Float? {
        return self.captureDevice?.lensPosition
    }
    
    func currentTemperature() -> Float? {
        if let gains = captureDevice?.deviceWhiteBalanceGains {
            let tempAndTint = captureDevice?.temperatureAndTintValues(for: gains)
            return tempAndTint?.temperature
        }
        return nil
    }
    
    func setCustomWhiteBalanceWithTemperature(temperature:Float) {
        
        performConfigurationOnCurrentCameraDevice { (currentDevice) -> Void in
            if currentDevice.isWhiteBalanceModeSupported(.locked) {
                let currentGains = currentDevice.deviceWhiteBalanceGains
                let currentTint = currentDevice.temperatureAndTintValues(for: currentGains).tint
                let temperatureAndTintValues = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: temperature, tint: currentTint)
                
                var deviceGains = currentDevice.deviceWhiteBalanceGains(for: temperatureAndTintValues)
                let maxWhiteBalanceGain = currentDevice.maxWhiteBalanceGain
                deviceGains.clampGainsToRange(minVal: 1, maxVal: maxWhiteBalanceGain)
                
                currentDevice.setWhiteBalanceModeLocked(with: deviceGains) {
                    (timestamp:CMTime) -> Void in
                }
            }
        }
    }
    

    
    func performConfigurationOnCurrentCameraDevice(block: @escaping ((_ currentDevice:AVCaptureDevice) -> Void)) {
        if let currentDevice = self.captureDevice {
            performConfiguration { () -> Void in
                do {
                    try currentDevice.lockForConfiguration()
                    block(currentDevice)
                    currentDevice.unlockForConfiguration()
                }
                catch {}
            }
        }
    }
    
    func performConfiguration(block: @escaping (() -> Void)) {
        DispatchQueue.main.async(execute: { () -> Void in
            block()
        })
    }
}

extension AVCaptureDevice.WhiteBalanceGains {
    mutating func clampGainsToRange(minVal:Float, maxVal:Float) {
        blueGain = max(min(blueGain, maxVal), minVal)
        redGain = max(min(redGain, maxVal), minVal)
        greenGain = max(min(greenGain, maxVal), minVal)
    }
}

extension ViewController : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {
        guard error == nil,
            let photoSampleBuffer = photoSampleBuffer else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }

        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
            return
        }

        let capturedImage = UIImage.init(data: imageData , scale: 1.0)
        if let image = capturedImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
}
