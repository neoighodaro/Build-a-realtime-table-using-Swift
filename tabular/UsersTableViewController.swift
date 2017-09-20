//
//  UsersTableViewController.swift
//  tabular
//
//  Created by Neo Ighodaro on 17/09/2017.
//  Copyright © 2017 CreativityKills Co. All rights reserved.
//

import UIKit
import Alamofire
import PusherSwift

class UsersTableViewController: UITableViewController {
    
    var pusher:Pusher!
    
    var deviceId : String = ""
    
    var textField: UITextField!
    
    var users : [NSDictionary] = []
    
    var indicator = UIActivityIndicatorView()
    
    var endpoint : String = "http://localhost:4000"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelection = false
        
        deviceId = UIDevice.current.identifierForVendor!.uuidString
        
        navigationItem.title = "Users List"
        navigationItem.rightBarButtonItem = self.editButtonItem
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAddUserAlertController))
        
        setupActivityIndicator()
        loadUsersFromApi()
        
        listenToChangesFromPusher()
    }
    
    private func listenToChangesFromPusher() {
        pusher = Pusher(key: "PUSHER_KEY", options: PusherClientOptions(host: .cluster("PUSHER_CLUSTER")))
        
        let channel = pusher.subscribe("userslist")
        
        let _ = channel.bind(eventName: "addUser", callback: { (data: Any?) -> Void in
            if let data = data as? [String : AnyObject] {
                if let name = data["name"] as? String {
                    if (data["deviceId"] as! String) != self.deviceId {
                        self.users.append(["id": self.users.count, "name": name])
                        self.tableView.reloadData()
                    }
                }
            }
        })
        
        let _ = channel.bind(eventName: "removeUser", callback: { (data: Any?) -> Void in
            if let data = data as? [String : AnyObject] {
                if let _ = data["index"] as? Int {
                    let indexPath = IndexPath(item: (data["index"] as! Int), section:0)
                    
                    if (data["deviceId"] as! String) != self.deviceId {
                        self.users.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        })
        
        let _ = channel.bind(eventName: "moveUser", callback: { (data: Any?) -> Void in
            if let data = data as? [String : AnyObject] {
                if let _ = data["deviceId"] as? String {
                    let sourceIndexPath = IndexPath(item:(data["src"] as! Int), section:0)
                    let destinationIndexPath = IndexPath(item:(data["dest"] as! Int), section:0)
                    let movedObject = self.users[sourceIndexPath.row]
                    
                    if (data["deviceId"] as! String) != self.deviceId {
                        self.users.remove(at: sourceIndexPath.row)
                        self.users.insert(movedObject, at: destinationIndexPath.row)
                        self.tableView.reloadData()
                    }
                }
            }
        })
        
        pusher.connect()
    }
    
    private func loadUsersFromApi() {
        indicator.startAnimating()
        
        Alamofire.request(self.endpoint + "/users").validate().responseJSON { (response) in
            switch response.result {
            case .success(let JSON):
                self.users = JSON as! [NSDictionary]
                self.tableView.reloadData()
                self.indicator.stopAnimating()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func setupActivityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        indicator.activityIndicatorViewStyle = .white
        indicator.backgroundColor = UIColor.darkGray
        indicator.center = self.view.center
        indicator.layer.cornerRadius = 05
        indicator.hidesWhenStopped = true
        indicator.layer.zPosition = 1
        indicator.isOpaque = false
        indicator.tag = 999
        tableView.addSubview(indicator)
    }
    
    public func showAddUserAlertController() {
        let alertCtrl = UIAlertController(title: "Add User", message: "Add a user to the list", preferredStyle: .alert)
        
        // Add text field to alert controller
        alertCtrl.addTextField { (textField) in
            self.textField = textField
            self.textField.autocapitalizationType = .words
            self.textField.placeholder = "e.g John Doe"
        }
        
        // Add cancel button to alert controller
        alertCtrl.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // "Add" button with callback
        alertCtrl.addAction(UIAlertAction(title: "Add", style: .default, handler: { action in
            if let name = self.textField.text, name != "" {
                let payload: Parameters = ["name": name, "deviceId": self.deviceId]
                
                Alamofire.request(self.endpoint + "/add", method: .post, parameters:payload).validate().responseJSON { (response) in
                    switch response.result {
                    case .success(_):
                        self.users.append(["id": self.users.count, "name" :name])
                        self.tableView.reloadData()
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }))
        
        present(alertCtrl, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "user", for: indexPath)
        cell.textLabel?.text = users[indexPath.row]["name"] as! String?
        return cell
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = users[sourceIndexPath.row]
        
        let payload:Parameters = [
            "deviceId": self.deviceId,
            "src":sourceIndexPath.row,
            "dest": destinationIndexPath.row,
            "src_id": users[sourceIndexPath.row]["id"]!,
            "dest_id": users[destinationIndexPath.row]["id"]!
        ]
        
        Alamofire.request(self.endpoint+"/move", method: .post, parameters: payload).validate().responseJSON { (response) in
            switch response.result {
            case .success(_):
                self.users.remove(at: sourceIndexPath.row)
                self.users.insert(movedObject, at: destinationIndexPath.row)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let payload: Parameters = [
                "index":indexPath.row,
                "deviceId": self.deviceId,
                "id": self.users[indexPath.row]["id"]!
            ]
            
            Alamofire.request(self.endpoint + "/delete", method: .post, parameters:payload).validate().responseJSON { (response) in
                switch response.result {
                case .success(_):
                    self.users.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                case .failure(let err):
                    print(err)
                }
            }
        }
    }
}
