//
//  ViewController.swift
//  GoWhipIt
//
//  Created by Takis Tap on 05/09/16.
//  Copyright © 2016 CommunicatieToegepast. All rights reserved.
//
//  Gebleven bij les 163 10:00



import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import CameraManager
import FacebookCore
import FacebookLogin
import FacebookShare


class CameraVC:  UIViewController {

    let cameraManager = CameraManager()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        Current.type = "foto"
        
        recordingAlert.isHidden = true
        self.setupCamera()
        self.title = "Camera"
        self.loader.stopAnimating()

        self.registerObservers()	
        self.addOverlay();
        
        // tijdelijk video uitschakelen
        self.changeModusOutlet2.isHidden = true
        self.cameraBtn.isHidden = true
        
//        //Current User need user to prompt uploads remaining
//        
//        let usrDefaults = UserDefaults.standard
//        let userName = usrDefaults.string(forKey: "loggedInUser")
//        
//        //create database reference
//        var ref: FIRDatabaseReference!
//        ref = FIRDatabase.database().reference()
//
//        //Set user ID
//        let currentUser = MD5(userName!)!
//       
//        //Check for uploadsremaing/total and calculate new values
//        ref.child("Users").child(currentUser).observeSingleEvent(of: .value, with: { (snapshot) in
//            
//            // Get user value
//            let value = snapshot.value as? NSDictionary
//            let uploadsRem = value?["uploadsRem"] as? Int
//
//            let alert = UIAlertController(title: "Remaining Uploads", message: "You have \(uploadsRem!) uploads remaining", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//            
//        }) { (error) in
//            print(error.localizedDescription)
//        }
    }

    
    override func viewDidAppear(_ animated: Bool) {
        self.loader.stopAnimating()
        let fileManager = FileManager.default
        let filename = getDocumentsDirectory().appendingPathComponent("result-01.mov")
        if fileManager.fileExists(atPath: filename.path) {
        
        do {
            try fileManager.removeItem(atPath: filename.path)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        }
        guard FIRAuth.auth()?.currentUser != nil else {
            print("Niet ingelogd CameraVC")
            performSegue(withIdentifier: "LoginVC", sender: nil)
            return
        }        
        
    }
    
    //adding MD5 support to rename users to fit Firebase
    func MD5(_ string: String) -> String? {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        
        if let d = string.data(using: String.Encoding.utf8) {
            d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
                CC_MD5(body, CC_LONG(d.count), &digest)
            }
        }
        return (0..<length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }
    
    func registerObservers()
    {
        let nc = NotificationCenter.default
        // Add notifies for selections
        nc.addObserver(self, selector: #selector(addOverlay), name: NSNotification.Name(rawValue: "RefreshOverlay"), object: nil)
    }
    
    func addOverlay()
    {
        let filename = getDocumentsDirectory().appendingPathComponent("photoframe.png")
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: filename.path) {
            guard let topImage = UIImage(contentsOfFile: filename.path) else {
                saveImageOverlay()
                return
            }
            overlayView.image = topImage
        }else{
            print("Overlay image bestaat nog niet")
            saveImageOverlay()
        }
    }
    
    func saveImageOverlay()
    {
        let fileManager = FileManager.default
        let filename = getDocumentsDirectory().appendingPathComponent("photoframe.png")
        if fileManager.fileExists(atPath: filename.path) {
            
            try! fileManager.removeItem(atPath: filename.path)
        }
        
        let usrDefaults = UserDefaults.standard
        let userName = usrDefaults.string(forKey: "loggedInUser")
        
        let storageRef = FIRStorage.storage().reference()
        let photoRef = storageRef.child("Overlays").child(userName!).child("photoframe.png")
        photoRef.downloadURL { (url, error) in
            if error == nil {
                let data = NSData(contentsOf: url!)
                let image = UIImage(data: data! as Data)
                if let data = UIImagePNGRepresentation(image!) {
                    
                    let filename = self.getDocumentsDirectory().appendingPathComponent("photoframe.png")
                    try? data.write(to: filename)
                    let nc = NotificationCenter.default
                    nc.post(name: Foundation.Notification.Name(rawValue: "RefreshOverlay"), object: nil);
                    
                    guard let topImage = UIImage(contentsOfFile: filename.path) else {
                        return
                    }
                    self.overlayView.image = topImage
                }
            } else {
                print(error!.localizedDescription)
            }
            
        }
    }
    
    func setupCamera()
    {
        cameraManager.addPreviewLayerToView(self.previewView)
        cameraManager.cameraDevice = .back
        cameraManager.cameraOutputQuality = .high
        cameraManager.flashMode = .auto
        cameraManager.writeFilesToPhoneLibrary = false
        cameraManager.showAccessPermissionPopupAutomatically = true
        cameraManager.cameraOutputMode = .stillImage
    }
    
    
    @IBAction func changeCameraBtn(_ sender: AnyObject) {
        //changeCamera()
        if(cameraManager.cameraDevice == .back){
            cameraManager.cameraDevice = .front
        }else{
            cameraManager.cameraDevice = .back
        }
        
    }
    
    
    @IBOutlet var overlayView: UIImageView!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var stillBtn: UIButton!
    @IBOutlet weak var cameraBtn: UIButton!
    @IBOutlet weak var recordingAlert: UIImageView!
    @IBOutlet var previewView: UIView!
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var changeModusOutlet2: UIButton!
    @IBAction func changeModus2(_ sender: AnyObject) {
        print("Press")
        if(Current.type == "video"){
            Current.type = "foto"
            self.title = "Create Image"
            cameraManager.cameraOutputMode = .stillImage
            changeModusOutlet2.setTitle("Video", for: UIControlState.normal)
            
        }else{
            Current.type = "video"
            self.title = "Video maken"
            cameraManager.cameraOutputMode = .videoWithMic
            changeModusOutlet2.setTitle("Foto", for: UIControlState.normal)
        }
    }
    
    
    @IBOutlet var recordNowOutlet: UIButton!
    @IBAction func recordNow(_ sender: AnyObject) {
        if(Current.type == "video"){
            let randomName = UUID().uuidString;
            let filename = getDocumentsDirectory().appendingPathComponent(randomName+"-0.mov")
            
            let myVideoURL = NSURL(fileURLWithPath: filename.path)
            recordNowOutlet.setImage(UIImage(named: "rec-red.png"), for: UIControlState.normal)
            cameraManager.startRecordingVideo()
            cameraManager.stopVideoRecording({ (videoURL, error) -> Void in
                try! FileManager.default.copyItem(at: videoURL!, to: myVideoURL as URL)
                Current.type = "video"
                Current.videoName = filename.path
                self.recordNowOutlet.setImage(UIImage(named: "rec-white.png"), for: UIControlState.normal)
                self.performSegue(withIdentifier: "goToCheckPhoto", sender: self)
            })
            
        }else{
            self.loader.startAnimating()
            cameraManager.capturePictureWithCompletion({ (image, error) -> Void in
                SharedFunctions.sharedInstance.addImage(image: image!)
                Current.type = "foto"
                
                self.performSegue(withIdentifier: "goToCheckPhoto", sender: self)
                
            })
        }
    }
    
    
    @IBAction func uitloggen(_ sender: AnyObject) {
        
        _ = try! FIRAuth.auth()?.signOut()
        performSegue(withIdentifier: "LoginVC", sender: nil)
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
