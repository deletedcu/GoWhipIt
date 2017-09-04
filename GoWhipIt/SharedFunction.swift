//
//  SharedFunction.swift
//  GoWhipIt
//
//  Created by Daan Kloek on 24-09-16.
//  Copyright © 2016 Weborganiser B.V.. All rights reserved.
//

import Foundation
import UIKit

class SharedFunctions: NSObject {
    
    static let sharedInstance = SharedFunctions();
    var Images: Array<UIImage> = []
    
    func addImage(image:UIImage)
    {
        self.Images += [image];
    }
    
    func getImages()-> Array<UIImage>
    {
        return self.Images;
    }
    
    func editImage(image:UIImage, index:Int)
    {
        self.Images[index] = image;
    }
    
    func deleteimage(index:Int)
    {
        self.Images.remove(at: index)
    }
    
    func emptyImages()
    {
        self.Images = [];
    }
    

    
}
