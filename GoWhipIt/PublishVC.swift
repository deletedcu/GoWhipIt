//
//  PublishVC.swift
//  GoWhipIt
//
//  Created by Takis Tap on 07/09/16.
//  Copyright © 2016 CommunicatieToegepast. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SwiftSpinner
import FBSDKShareKit

class PublishVC: UIViewController {
    
    let usrDefaults = UserDefaults.standard
    let fileManager = FileManager.default
    
    fileprivate var localFile: NSURL?
    fileprivate var riversRef: FIRStorageReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Preview"
        bekijkVideoOutlet.isHidden = true;
        
        
        switch(Current.type) {
        case "foto"  :
            self.showPhoto();
            self.loader.stopAnimating()
            break;
        case "video"  :
            self.loader.startAnimating()
            self.showVideo();
            break;
            
        default :
            print("Error");
            self.loader.stopAnimating()
        }
        
    }
    
    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)
        
        if (self.isMovingFromParentViewController){
            SharedFunctions.sharedInstance.emptyImages()
            
            if fileManager.fileExists(atPath: Current.videoName) {
                do {
                    try fileManager.removeItem(atPath: Current.videoName)
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
            }
            
            
            Current.videoName = "";
            //Current.type = "";
            
            let filename = getDocumentsDirectory().appendingPathComponent("result-01.mov")
            if self.fileManager.fileExists(atPath: filename.path) {
                do {
                    try self.fileManager.removeItem(atPath: filename.path)
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
            }
            
        }
    }
    
    //Function to HASH user email to fit backend
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
    
    @IBAction func copyFacebookContentToClipboard(_ sender: AnyObject) {
        //Get user logged in
        let userName = usrDefaults.string(forKey: "loggedInUser")
    
        //create database reference to image
        var ref: FIRDatabaseReference!
        ref = FIRDatabase.database().reference()
        
        //Covert user ID to backend unfriendly name
        let currentUser = MD5(userName!)!
        
        //Get specific users facebook Content
        ref.child("Users").child(currentUser).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let facebookContent = value?["facebookContent"] as? String
            //Put in clipboard
            UIPasteboard.general.string = facebookContent
        })
        
    }
    
    @IBAction func preConfiguredFacebookContent(_ sender: AnyObject) {
        //Get user Loggedin
        let userName = usrDefaults.string(forKey: "loggedInUser")
        
        //create database reference to image
        var ref: FIRDatabaseReference!
        ref = FIRDatabase.database().reference()

        //Covert user ID to backend unfriendly name
        let currentUser = MD5(userName!)!
        
        //Check for specific users facebook Content
        ref.child("Users").child(currentUser).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get users Facebook value
            let value = snapshot.value as? NSDictionary
            let facebookContent = value?["facebookContent"] as? String
            
            // Create the alert controller.
            let alert = UIAlertController(title: "Facebook post", message: "Create a predefined facebook post to prevent typos and speed up posting", preferredStyle: .alert)
            
            // Add the text field.
            alert.addTextField { (textField) in
                textField.text = facebookContent
            }
            
            // Grab the value from the text field
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                
                let textField = alert!.textFields![0]
                ref.child("Users/\(currentUser)/facebookContent").setValue(textField.text)

            }))
            
            // Present the alert
            self.present(alert, animated: true, completion: nil)
        })
        
    }
    
    
    
    func showVideo()
    {
        
        self.addVideoOverlay()
        
    }
    
    func showPhoto()
    {
        
        let bottomImage = RBSquareImage(image: SharedFunctions.sharedInstance.getImages()[0])
        print(getDocumentsDirectory().absoluteString)
        let filename = getDocumentsDirectory().appendingPathComponent("photoframe.png")
        let filePath = filename.path
        print(filePath)
        
        let topImage = UIImage(named: filePath)
        
        let size = CGSize(width: bottomImage.size.width, height: bottomImage.size.height)
        UIGraphicsBeginImageContext(size)
        
        let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        bottomImage.draw(in: areaSize)
        
        topImage!.draw(in: areaSize, blendMode: .normal, alpha: 1.0)
        
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let ImageView = UIImageView(image: newImage)
        let sizeOfImageView = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: self.view.frame.size.width, height: (self.view.frame.size.height - 0.0)))
        
        ImageView.frame = sizeOfImageView
        ImageView.contentMode = UIViewContentMode.scaleAspectFit
        self.view.addSubview(ImageView);
        
        
    }
    
    func RBSquareImage(image originalImage: UIImage) -> UIImage {
        
        // Create a copy of the image without the imageOrientation property so it is in its native orientation (landscape)
        let contextImage: UIImage = UIImage(cgImage: originalImage.cgImage!)
        
        // Get the size of the contextImage
        let contextSize: CGSize = contextImage.size
        
        let posX: CGFloat
        let posY: CGFloat
        let width: CGFloat
        let height: CGFloat
        
        // Check to see which length is the longest and create the offset based on that length, then set the width and height of our rect
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            width = contextSize.height
            height = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            width = contextSize.width
            height = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX,y: posY,width: width,height: height)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: originalImage.scale, orientation: originalImage.imageOrientation)
        
        return image
        
    }
    
    //    @IBAction func deletePhoto(_ sender: AnyObject) {
    //        SharedFunctions.sharedInstance.emptyImages()
    //
    //        //Current.type = "";
    //
    //        let filename = getDocumentsDirectory().appendingPathComponent("result-01.mov")
    //        if self.fileManager.fileExists(atPath: filename.path) {
    //            do {
    //                try self.fileManager.removeItem(atPath: filename.path)
    //                print("Ik kan het niet")
    //            }
    //            catch let error as NSError {
    //                print("Ooops! Something went wrong: \(error)")
    //            }
    //        }
    //
    //        if self.fileManager.fileExists(atPath: Current.videoName) {
    //            do {
    //                try self.fileManager.removeItem(atPath: Current.videoName)
    //            }
    //            catch let error as NSError {
    //                print("Ooops! Something went wrong: \(error)")
    //            }
    //        }
    //
    //
    //        Current.videoName = "";
    //        //navigationController?.popViewController(animated: true)
    //    }
    
    @IBAction func publish(_ sender: AnyObject) {
        
//        switch(Current.type) {
//        case "foto"  :
//            self.publishPhoto()
//            break;
//        case "video"  :
//            self.publishVideo()
//            break;
//            
//        default :
//            print("Error");
//        }
        
        let actionSheet = UIAlertController(title: "Select Type", message: "Select the facebook post type.", preferredStyle: .actionSheet)
        let profileAction = UIAlertAction(title: "Share to Facebook Profile", style: .default) { action in
                    switch(Current.type) {
                    case "foto"  :
                        self.publishPhoto()
                        break;
                    case "video"  :
                        self.publishVideo()
                        break;
            
                    default :
                        print("Error");
                    }
        }

        let pageAction = UIAlertAction(title: "Share to Facebook Page", style: .default) { action in
            self.showShareVC()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(profileAction)
        actionSheet.addAction(pageAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    func showShareVC() {
        SwiftSpinner.show("Preparing Facebook share")
        let randomName = UUID().uuidString;
        
        // Eerst foto opslaan op toestel in app data niet in photo library!
        
        for i in 0..<SharedFunctions.sharedInstance.getImages().count {
            
            let bottomImage = RBSquareImage(image: SharedFunctions.sharedInstance.getImages()[i])
            let filename = getDocumentsDirectory().appendingPathComponent("photoframe.png")
            let topImage = UIImage(named: filename.path)
            
            let size = CGSize(width: bottomImage.size.width, height: bottomImage.size.height)
            UIGraphicsBeginImageContext(size)
            
            let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            bottomImage.draw(in: areaSize)
            
            
            topImage!.draw(in: areaSize, blendMode: .normal, alpha: 1.0)
            
            let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            if let data = UIImageJPEGRepresentation(newImage, 1) {
                
                let filename = getDocumentsDirectory().appendingPathComponent(randomName+"-"+String(i)+".jpg")
                try? data.write(to: filename)
                
            }
        }
        
        // Foto is nu als bestand weggeschreven
        // Uploaden naar FireBase Google
        let userName = usrDefaults.string(forKey: "loggedInUser")
        
        //store image to storage
        let storage = FIRStorage.storage()
        let storageRef = storage.reference()
        
        //create database reference to image
        var ref: FIRDatabaseReference!
        ref = FIRDatabase.database().reference()

        // File located on disk
        let filename = getDocumentsDirectory().appendingPathComponent(randomName+"-0.jpg")
        localFile = NSURL(fileURLWithPath: filename.path)

        // Create a reference to the file you want to upload
        riversRef = storageRef.child("Image/"+userName!+"/"+randomName+"-0.jpg")
        
        guard
            let localFile = localFile else {
                SwiftSpinner.hide()
                
                return
        }

        //Set user ID
        let currentUser = MD5(userName!)!
        
        //Check for uploadsremaing/total and calculate new values
        ref.child("Users").child(currentUser).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let uploadsTot = value?["uploadsTot"] as? Int
            
            let newUploadsTot = uploadsTot! + 1
            
            ref.child("Users/\(currentUser)/uploadsTot").setValue(newUploadsTot)
            
            guard
                let imagePath = localFile.path,
                let imageData = self.fileManager.contents(atPath: imagePath),
                let imageToShare = UIImage(data: imageData) else {
                    return
            }
            
            self.uploadPhoto(photo: imageToShare, atReference: self.riversRef!, completion: { (imageUrl) in
                SwiftSpinner.hide()
                if let urlString = imageUrl {
                    print(urlString)
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let shareVC = storyboard.instantiateViewController(withIdentifier: "ShareVC") as! ShareVC
                    shareVC.modalPresentationStyle = .overCurrentContext
                    shareVC.image = imageToShare
                    shareVC.imageURL = urlString
                    shareVC.delegate = self
                    self.present(shareVC, animated: true, completion: nil)
                }
            })
            
            
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func publishVideo()
    {
        SwiftSpinner.show("Bezig met uploaden van video...")
        
        let randomName = UUID().uuidString;
        
        // Uploaden naar FireBase Google
        let userName = usrDefaults.string(forKey: "loggedInUser")
        
        let storage = FIRStorage.storage()
        
        let storageRef = storage.reference()
        
        // File located on disk
        let filename = getDocumentsDirectory().appendingPathComponent("result-01.mov")
        localFile = NSURL(fileURLWithPath: filename.path)
        
        // Create a reference to the file you want to upload
        riversRef = storageRef.child("Video/"+userName!+"/"+randomName+"-0.mov")
        
        guard
            let localFile = localFile,
            let riversRef = riversRef else {
                SwiftSpinner.hide()
                
                return
        }
        
        // Upload the file to the path "images/rivers.jpg"
        _ = riversRef.putFile(localFile as URL, metadata: nil) { metadata, error in
            if (error != nil) {
                // Uh-oh, an error occurred!
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                SwiftSpinner.hide()
                
                SharedFunctions.sharedInstance.emptyImages()
                
                if self.fileManager.fileExists(atPath: Current.videoName) {
                    do {
                        try self.fileManager.removeItem(atPath: Current.videoName)
                    }
                    catch let error as NSError {
                        print("Ooops! Something went wrong: \(error)")
                    }
                }
                let filename = self.getDocumentsDirectory().appendingPathComponent("result-01.mov")
                if self.fileManager.fileExists(atPath: filename.path) {
                    do {
                        try self.fileManager.removeItem(atPath: filename.path)
                    }
                    catch let error as NSError {
                        print("Ooops! Something went wrong: \(error)")
                    }
                }
                
                Current.videoName = "";
                Current.type = "";
                _ = self.navigationController?.popViewController(animated: true)
                
            }
        }
        
    }
    
    
    
    
    func publishPhoto()
    {
        SwiftSpinner.show("Preparing Facebook share")
        let randomName = UUID().uuidString;

        // Eerst foto opslaan op toestel in app data niet in photo library!
        
        for i in 0..<SharedFunctions.sharedInstance.getImages().count {
            
            let bottomImage = RBSquareImage(image: SharedFunctions.sharedInstance.getImages()[i])
            let filename = getDocumentsDirectory().appendingPathComponent("photoframe.png")
            let topImage = UIImage(named: filename.path)
            
            let size = CGSize(width: bottomImage.size.width, height: bottomImage.size.height)
            UIGraphicsBeginImageContext(size)
            
            let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            bottomImage.draw(in: areaSize)
            
            
            topImage!.draw(in: areaSize, blendMode: .normal, alpha: 1.0)
            
            let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            if let data = UIImageJPEGRepresentation(newImage, 1) {
                
                let filename = getDocumentsDirectory().appendingPathComponent(randomName+"-"+String(i)+".jpg")
                try? data.write(to: filename)
                
            }
        }
        
        // Foto is nu als bestand weggeschreven
        // Uploaden naar FireBase Google
        let userName = usrDefaults.string(forKey: "loggedInUser")

        //store image to storage
        let storage = FIRStorage.storage()
        let storageRef = storage.reference()

        //create database reference to image
        var ref: FIRDatabaseReference!
        ref = FIRDatabase.database().reference()

        // File located on disk
        let filename = getDocumentsDirectory().appendingPathComponent(randomName+"-0.jpg")
        localFile = NSURL(fileURLWithPath: filename.path)

        // Create a reference to the file you want to upload
        riversRef = storageRef.child("Image/"+userName!+"/"+randomName+"-0.jpg")

        guard
            let localFile = localFile,
            let _ = riversRef else {
                SwiftSpinner.hide()
                
                return
        }

        //Set user ID
        let currentUser = MD5(userName!)!

        //Check for uploadsremaing/total and calculate new values
        ref.child("Users").child(currentUser).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let uploadsTot = value?["uploadsTot"] as? Int
            //let uploadsRem = value?["uploadsRem"] as? Int
            
//            if (uploadsRem! <= 0) {
//                
//                //Present user with alert to buy new uploads
//                let alert = UIAlertController(title: "No remaining uploads", message: "Please upgrade your account to publish images to your campaign.", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//                SwiftSpinner.hide()
//                _ = self.navigationController?.popViewController(animated: true)
//                
//            } else {

                let newUploadsTot = uploadsTot! + 1
                //let newUploadsRem = uploadsRem! - 1

                //testing write to firebase database
                //ref.child("Users/\(currentUser)/uploadsRem").setValue(newUploadsRem)
                ref.child("Users/\(currentUser)/uploadsTot").setValue(newUploadsTot)

                guard
                    let imagePath = localFile.path,
                    let imageData = self.fileManager.contents(atPath: imagePath),
                    let imageToShare = UIImage(data: imageData) else {
                        print("Can't get image at \(localFile.path)")
                        
                        return
                }
                SwiftSpinner.hide()
                
                let sharePhoto = FBSDKSharePhoto(image: imageToShare, userGenerated: true)
                
                let sharePhotoContent = FBSDKSharePhotoContent()
                sharePhotoContent.photos = [sharePhoto!]
                
                FBSDKShareDialog.show(from: self, with: sharePhotoContent, delegate: self)
            // }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func uploadPhoto(photo: UIImage?, atReference reference: FIRStorageReference, completion: @escaping (String?) -> Void) {
        if let png = photo?.resizeWith(width: 960)?.pngRepresentation {
            reference.put(png, metadata: nil, completion: { (metadata, err) in
                if err != nil {
                    print(err?.localizedDescription ?? "Error")
                    completion(nil)
                } else {
                    completion(metadata?.downloadURL()?.absoluteString)
                }
            })
        }
    }
    
    // Video overlay toevoegen
    func addVideoOverlay()
    {
        
        let fileURL = NSURL(fileURLWithPath: Current.videoName)
        
        let composition = AVMutableComposition()
        let vidAsset = AVURLAsset(url: fileURL as URL, options: nil)
        
        // get video track
        let vtrack =  vidAsset.tracks(withMediaType: AVMediaTypeVideo)
        let videoTrack:AVAssetTrack = vtrack[0]
        // Get audio
        let vaudio =  vidAsset.tracks(withMediaType: AVMediaTypeAudio)
        let videoTrackAudio:AVAssetTrack = vaudio[0]
        
        
        let vid_duration = videoTrack.timeRange.duration
        let vid_timerange = CMTimeRangeMake(kCMTimeZero, vid_duration)
        
        let compositionvideoTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        
        let compositionaudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        
        
        
        try! compositionvideoTrack.insertTimeRange(vid_timerange, of: videoTrack, at: kCMTimeZero)
        try! compositionaudioTrack.insertTimeRange(vid_timerange, of: videoTrackAudio, at: kCMTimeZero)
        
        //compositionvideoTrack.preferredTransform = CGAffineTransform(rotationAngle: (CGFloat.pi / 2))//videoTrack.preferredTransform
        
        //videoTrack.preferredTransform = CGAffineTransform(rotationAngle: (CGFloat.pi / 2))
        
        
        // Watermark Effect
        let size = videoTrack.naturalSize
        let filename2 = getDocumentsDirectory().appendingPathComponent("photoframe.png")
        let imglogo = UIImage(named: filename2.path)
        let imglayer = CALayer()
        imglayer.contents = imglogo?.cgImage
        imglayer.frame = CGRect(x: 0, y: (size.width / 4), width: size.height, height: size.height)
        imglayer.opacity = 1.0
        
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.height, height: size.width)
        
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.height, height: size.width)
        parentlayer.addSublayer(videolayer)
        parentlayer.addSublayer(imglayer)
        
        print(size.height)
        print(size.width)
        
        let layercomposition = AVMutableVideoComposition()
        layercomposition.frameDuration = CMTimeMake(1, 30)
        //layercomposition.renderSize = size
        layercomposition.renderSize = CGSize(width: size.height, height: size.width)
        layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        
        // instruction for image
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration)
        let videotrack = composition.tracks(withMediaType: AVMediaTypeVideo)[0] as AVAssetTrack
        let audiotrack = composition.tracks(withMediaType: AVMediaTypeAudio)[0] as AVAssetTrack
        
        let layerinstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: audiotrack)
        instruction.layerInstructions = NSArray(object: layerinstruction1) as! [AVVideoCompositionLayerInstruction]
        //layercomposition.instructions = NSArray(object: instruction) as! [AVVideoCompositionInstructionProtocol]
        
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        let transform1 = CGAffineTransform.identity
        let transform2 = CGAffineTransform(translationX: size.height, y: 0).concatenating(transform1)
        let transform3 = CGAffineTransform(rotationAngle: CGFloat(90).degreesToRadians).concatenating(transform2)
        let transform4 = CGAffineTransform(scaleX: 1, y: 1).concatenating(transform3)
        layerinstruction.setTransform(transform4, at: kCMTimeZero)
        
        instruction.layerInstructions = NSArray(object: layerinstruction) as! [AVVideoCompositionLayerInstruction]
        layercomposition.instructions = NSArray(object: instruction) as! [AVVideoCompositionInstructionProtocol]
        
        //  create new file to receive data
        let filename = getDocumentsDirectory().appendingPathComponent("result-01.mov")
        let movieDestinationUrl = NSURL(fileURLWithPath: filename.path)
        
        // use AVAssetExportSession to export video
        let assetExport = AVAssetExportSession(asset: composition, presetName:AVAssetExportPresetHighestQuality)
        assetExport?.videoComposition = layercomposition
        assetExport?.outputFileType = AVFileTypeQuickTimeMovie
        
        assetExport?.outputURL = movieDestinationUrl as URL
        //assetExport?.shouldOptimizeForNetworkUse = true
        
        assetExport?.exportAsynchronously(completionHandler: {() -> Void in
            
            self.showVideoPopup(filename: NSURL(fileURLWithPath: filename.path))
            
        })
        
    }
    
    func showVideoPopup(filename:NSURL)
    {
        OperationQueue.main.addOperation {
            self.loader.stopAnimating()
            self.bekijkVideoOutlet.isHidden = false;
            
            // play video
            let player = AVPlayer(url: filename as URL)
            let playerController = AVPlayerViewController()
            playerController.player = player
            
            
            self.present(playerController, animated: true) {
                player.play()
            }
        }
        
        if self.fileManager.fileExists(atPath: Current.videoName) {
            do {
                try self.fileManager.removeItem(atPath: Current.videoName)
            }
            catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
        }
        
    }
    
    @IBAction func bekijkVideo(_ sender: AnyObject) {
        let filename = getDocumentsDirectory().appendingPathComponent("result-01.mov")
        
        let player = AVPlayer(url: NSURL(fileURLWithPath: filename.path) as URL)
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        
        self.present(playerController, animated: true) {
            player.play()
        }
    }
    
    @IBOutlet var bekijkVideoOutlet: RoundedButton!
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var imageView1: UIImageView!
    
}

extension PublishVC: FBSDKSharingDelegate {
    func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable : Any]!) {
        guard
            let localFile = localFile,
            let localFilePath = localFile.path,
            let riversRef = riversRef else {
                return
        }
        
        successFacebookShare()
//        SwiftSpinner.show("step uploading to firebase")
//        // Upload the file to the path "images/rivers.jpg"
//        _ = riversRef.putFile(localFile as URL, metadata: nil) { metadata, error in
//            if (error != nil) {
//                // Uh-oh, an error occurred!
//            } else {
//                // Metadata contains file metadata such as size, content-type, and download URL.
//                SwiftSpinner.hide()
//                SharedFunctions.sharedInstance.emptyImages()
//                if self.fileManager.fileExists(atPath: localFilePath) {
//                    do {
//                        try self.fileManager.removeItem(atPath: localFilePath)
//                    }
//                    catch let error as NSError {
//                        print("Ooops! Something went wrong: \(error)")
//                    }
//                }
//                
//                Current.videoName = "";
//                Current.type = "";
//                _ = self.navigationController?.popViewController(animated: true)
//                
//            }
//        }
    }
    
    func sharer(_ sharer: FBSDKSharing!, didFailWithError error: Error!) {
        print(error)
    }
    
    func sharerDidCancel(_ sharer: FBSDKSharing!) {
        
        cancelFacebookShare()
    }
    
    func cancelFacebookShare() {
        let userName = usrDefaults.string(forKey: "loggedInUser")
        
        //create database reference to image
        var ref: FIRDatabaseReference!
        ref = FIRDatabase.database().reference()
        
        //Set user ID
        let currentUser = MD5(userName!)!
        
        //Check for uploadsremaing/total and calculate new values
        ref.child("Users").child(currentUser).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let uploadsTot = value?["uploadsTot"] as? Int
            // let uploadsRem = value?["uploadsRem"] as? Int
            
            let newUploadsTot = uploadsTot! - 1
            // let newUploadsRem = uploadsRem! + 1
            
            //testing write to firebase database
            // ref.child("Users/\(currentUser)/uploadsRem").setValue(newUploadsRem)
            ref.child("Users/\(currentUser)/uploadsTot").setValue(newUploadsTot)
            
        })
    }
    
    func successFacebookShare() {
        
    }
    
    func failureFacebookShare(_ error: Error!) {
        print(error)
    }
    
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension PublishVC: ShareVCDelegate {
    
    func shareDidCancel() {
        cancelFacebookShare()
    }
    
    func shareSuccessed() {
        successFacebookShare()
    }
    
    func shareFailed(_ error: Error!) {
        failureFacebookShare(error)
    }
    
}
