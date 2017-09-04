//
//  ShareVC.swift
//  GoWhipIt
//
//  Created by Star on 9/1/17.
//  Copyright © 2017 CommunicatieToegepast. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import SDWebImage
import SwiftyJSON
import SwiftSpinner

protocol ShareVCDelegate {
    
    func shareDidCancel()
    
    func shareFailed(_ error: Error!)
    
    func shareSuccessed()
    
}

class ShareVC: UIViewController {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var postView: UIView!
    @IBOutlet weak var pageView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var emptyLabel: UILabel!
    
    var image: UIImage?
    var imageURL: String!
    var accessToken: String?
    var connection: GraphRequestConnection?
    var pageList: [Page] = []
    var selectedPage: Page!
    var delegate: ShareVCDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.5)
        mainView.layer.cornerRadius = 10
        mainView.clipsToBounds = true
        
        postView.isHidden = false
        pageView.isHidden = true
        postImageView.image = image
        captionTextField.delegate = self
        
        if let token = AccessToken.current {
            getFacebookInfo()
            getPageList()
        } else {
            DispatchQueue.main.async {
                self.showLoginAlert()
            }
        }
        
    }
    
    func showLoginAlert() {
        let alertController = UIAlertController(title: "Facebook Signin", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            self.facebookLogin()
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func facebookLogin() {
        let loginManager = LoginManager()
        loginManager.logIn([.publicProfile, .custom("pages_show_list")], viewController: self) { (loginResult) in
            switch loginResult {
            case .cancelled:
                break
            case .failed(let err):
                print(err)
                break
            case .success(let grantPermissions, let declinedPermissions, _):
                print(grantPermissions)
                print(declinedPermissions)
                self.getFacebookInfo()
                self.getPageList()
                break
            }
        }
    }
    
    func getFacebookInfo() {
        
        let graphRequest = GraphRequest(graphPath: "me", parameters: ["fields": "id, name"])
        graphRequest.start { response, result in
            switch result {
            case .success(let response):
                let json = JSON(response.dictionaryValue ?? [:])
                
                let id = json["id"].stringValue
                let name = json["name"].stringValue
                let url = "http://graph.facebook.com/\(id)/picture?type=square"
                
                self.nameLabel.text = name
                self.avatarImageView.sd_setImage(with: URL(string: url))
                
                break
            case .failed(let err):
                print(err)
                break
            }
        }
    }
    
    func getPageList() {
        
        let graphRequest = GraphRequest(graphPath: "me/accounts")
        graphRequest.start { response, result in
            
            switch result {
            case .success(let response):
                let json = JSON(response.dictionaryValue ?? [:])
                for jsonData in json["data"].arrayValue {
                    let page = Page(category: jsonData["category"].stringValue, id: jsonData["id"].stringValue, name: jsonData["name"].stringValue, token: jsonData["access_token"].stringValue)
                    self.pageList.append(page)
                }
                if self.pageList.count > 0 {
                    self.emptyLabel.isHidden = true
                    self.selectedPage = self.pageList[0]
                    self.updatePageName()
                } else {
                    self.emptyLabel.isHidden = false
                }
                self.tableView.reloadData()
                break
            case .failed(let err):
                print(err)
                break
            }
            
        }
    }
    
    func postPhoto() {
        captionTextField.endEditing(true)
        if (AccessToken.current?.grantedPermissions?.contains(Permission(name: "manage_pages")))! {
            sharePhoto()
        } else {
            let loginManage = LoginManager()
            loginManage.logIn([.publishActions, .custom("manage_pages"), .custom("publish_pages")], viewController: self, completion: { (loginResult) in
                switch loginResult {
                case .cancelled:
                    break
                case .failed(let err):
                    print(err)
                    self.showAlert("Permission error", message: err.localizedDescription)
                    break
                case .success(let grantPermissions, let declinedPermissions, _):
                    print(grantPermissions)
                    print(declinedPermissions)
                    self.sharePhoto()
                    break
                }
            })
        }
        
    }
    
    func sharePhoto() {
        SwiftSpinner.show("Sharing to Facebook page...")
        let caption = captionTextField.text!
        var currentToken = AccessToken.current!
        currentToken = AccessToken(appId: currentToken.appId, authenticationToken: selectedPage.token, userId: currentToken.appId, refreshDate: currentToken.refreshDate, expirationDate: currentToken.expirationDate, grantedPermissions: currentToken.grantedPermissions, declinedPermissions: currentToken.declinedPermissions)
        
        let graphRequest = GraphRequest(graphPath: "\(selectedPage.id)/photos", parameters: ["url": imageURL, "caption": caption], accessToken: currentToken, httpMethod: .POST)
        graphRequest.start { response, result in
            SwiftSpinner.hide()
            print(result)
            switch result {
            case .failed(let err):
                self.delegate.shareFailed(err)
                break
            case .success(let response):
                self.delegate.shareSuccessed()
                break
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func onPostButtonClick(_ sender: Any) {
        if selectedPage != nil {
            postPhoto()
        } else {
            showAlert("Empty page", message: "Please select the Facebook page")
        }
    }
    
    @IBAction func onCancelButtonClick(_ sender: Any) {
        delegate.shareDidCancel()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onPageButtonClick(_ sender: Any) {
        postView.isHidden = true
        pageView.isHidden = false
        tableView.reloadData()
    }
    
    @IBAction func onBackButtonClick(_ sender: Any) {
        pageView.isHidden = true
        postView.isHidden = false
    }
    
    func updatePageName() {
        guard let page = selectedPage else {return}
        pageLabel.text = page.name
    }
    
    func showAlert(_ title: String, message:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}

extension ShareVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPage = pageList[indexPath.row]
        pageView.isHidden = true
        postView.isHidden = false
        updatePageName()
    }
}

extension ShareVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let page = pageList[indexPath.row]
        cell.textLabel?.text = page.name
        if selectedPage != nil, selectedPage?.id == page.id {
            cell.accessoryType = .checkmark
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pageList.count
    }
    
}

extension ShareVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
