//
//  AuthService.swift
//  GoWhipIt
//
//  Created by Takis Tap on 07/09/16.
//  Copyright © 2016 CommunicatieToegepast. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseStorage
import Firebase


typealias Completion = (_ errMsg: String?, _ data: AnyObject?) -> Void


class AuthService {
    
    private static let _instance = AuthService()
  
    static var instance: AuthService {
        return _instance
    }
    
    func login(email: String, password: String, onComplete: Completion?) {
        _ = try! FIRAuth.auth()?.signOut()
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: {(user, error) in
            
            if error != nil {
                print("ERROR")
                if let errorCode = FIRAuthErrorCode(rawValue: error!._code)  {
                    //if user not found, create user
                    if errorCode == .errorCodeUserNotFound {
                        
                        self.handleFirebaseError(error: error! as NSError, onComplete: onComplete) 
//                        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: {(user, error) in
//                            if error != nil {
//                                //if error creating user
//                                self.handleFirebaseError(error: error! as NSError, onComplete: onComplete)
//                            } else {
                                //if login successfull
                                if user?.uid != nil {
                                    //Sign in
                                    FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: {(user, error)
                                        in
                                        if error != nil {
                                            self.handleFirebaseError(error: error! as NSError, onComplete: onComplete)
                                        } else {
                                            onComplete?(nil, user)
                                        }
                                    })
                                }
//                            }
//                        })
                    }
                } else {
                    self.handleFirebaseError(error: error! as NSError, onComplete: onComplete)
                }
            } else {
                onComplete?(nil, user)
            }
        })
    }
    
    func handleFirebaseError(error: NSError, onComplete: Completion?) {
        print(error.debugDescription)
        if let errorCode = FIRAuthErrorCode(rawValue: error.code) {
            
            switch(errorCode) {
            case .errorCodeUserNotFound:
                onComplete?("Unknown account, please register at gowhipit.com", nil)
                break
            case .errorCodeInvalidEmail:
                onComplete?("Invalid email adress", nil)
                break
            case .errorCodeWrongPassword:
                onComplete?("Invalid password", nil)
                break
            case .errorCodeEmailAlreadyInUse, .errorCodeAccountExistsWithDifferentCredential:
                onComplete?("Email already in use", nil)
                break
            default:
                onComplete?("There was a problem authenticating, try again", nil)
                break
            }
            
        }
        
    }
    
}
