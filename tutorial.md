# How to build a realtime table using Swift
More often than not, when you build applications to be consumed by others, you will need to represent the data in some sort of table or list. Think of a list of users for example, or a table filled with data about the soccer league. Now, imagine the data that populated the table was to be reordered or altered, it would be nice if everyone viewing the data on the table sees the changes made instantaneously.

In this article, you will see how you can use iOS and Pusher to create a table that is updated across all your devices in realtime. You can see a screen recording of how the application works below.


![](https://www.dropbox.com/s/82bv2ry4uwm0462/How-to-build-a-realtime-table-using-Swift-6.gif?raw=1)


In the recording below, you can see how the changes made to the table on the one device gets mirrored instantly to the other device and vice-versa. Let us consider how to make this using Pusher and Swift.


## Requirements for building a realtime table on iOS

For you to follow this tutorial, you will need all of the following requirements:


- A MacBook Pro
- [Xcode](https://developer.apple.com/xcode/) installed on your machine
- Basic knowledge of [Swift](https://developer.apple.com/swift/) and using Xcode 
- Basic knowledge of JavaScript (NodeJS)
- [NodeJS](https://docs.npmjs.com/getting-started/installing-node) and NPM installed on your machine 
- [Cocoapods](http://www.raywenderlich.com/12139/introduction-to-cocoapods) ****installed on your machine.
- A [Pusher](https://pusher.com) application.

If you have all the following then let us continue in the article.

## Preparing our environment to create our application

Launch Xcode and create a new project. Follow the new application wizard and create a new **Single-page application**. Once the project has been created, close Xcode and launch terminal.

In the terminal window, `cd` to the root of the app directory and run the command `pod init`. This will generate a **Podfile**. 

Update the contents of the **Podfile** to the contents below (replace `PROJECT_NAME` with your project name):


    platform :ios, '9.0'
    target 'PROJECT_NAME' do
      use_frameworks!
      pod 'PusherSwift', '~> 4.1.0'
      pod 'Alamofire', '~> 4.4.0'
    end

Save the **Podfile** and then run the command: `pod install` on your terminal window. Running this command will install all the third-party packages we need to build our realtime app. 

Once the installation is complete, open the `**.xcworkspace**` file in your project directory root. This should launch Xcode. Now we are ready to start creating our iOS application.

## Building the User Interface of our realtime table on iOS

Once Xcode has finished loading, we can now start building our interface.

Open the `Main.storyboard` file. Drag and drop a Navigation Controller to the storyboard and remove the entry point arrow from the current View Controller on the storyboard to the new Navigation Controller you just created and delete the old View Controller.  You should now have something like this in your storyboard:


![](https://www.dropbox.com/s/681umic4zosco3b/How-to-build-a-realtime-table-using-Swift-1.png?raw=1)


As seen in the screenshot, we have a simple navigation controller and we have made the table view controller attached to the navigation controller our Root View Controller.

Now, we need to add a reuse identifier to our table cells. Click on the prototype cell and add a new reuse identifier.


![](https://www.dropbox.com/s/yc8a68ja0m8w75t/How-to-build-a-realtime-table-using-Swift-2.png?raw=1)


We have named our reuse identifier **user** but you can call the reuse identifier whatever you want. Next, create a new `TableViewController` and attach the controller to the root view controller using the storyboard’s identity inspector as seen below:


![](https://www.dropbox.com/s/sl6d7lea5cl4ttt/How-to-build-a-realtime-table-using-Swift-3.png?raw=1)


Great! Now we are done with the user interface of the realtime table application, let us start creating the logic that will populate and make our iOS table realtime.


## Populating our iOS table with user data and manipulating it

The first thing we want to do is populate our table with some mock data. Once we do this, we can then add and test all the possible manipulations we want the table to have like moving rows around, deleting rows and adding new rows to the table.

Open your `UserTableViewController`. Now remove all the functions of the file except `viewDidLoad` so that we have clarity on the file. You should have something like this when you are done:


    import UIKit
    
    class UserTableViewController: UITableViewController {
    
        override func viewDidLoad() {
            super.viewDidLoad()
        }
    }

Now let us add mock data. Create a new function that is supposed to load the data from an API. For now, though, we will hardcode the data. Add the function below to the controller:


    private func loadUsersFromApi() {
        users = [
            [
                "id": 1,
                "name" : "John Doe",
            ],
            [
                "id": 2,
                "name": "Jane Doe"
            ]
        ]
    }

Now instantiate the `users` property on the class right under the class declaration:


    var users:[NSDictionary] = [] 

And finally, in the `viewDidLoad` function, call the `loadUsersFromApi` method:


    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadUsersFromApi()
    }

Next, we need to add all the functions that’ll make our table view controller compliant with the 
`UITableViewController` and thus display our data. Add the functions below to the view controller:


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
        users.remove(at: sourceIndexPath.row)
        users.insert(movedObject, at: destinationIndexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.users.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

The above code has 5 functions. The first function tells the table how many sections our table has. The next function tells the table how many users (or rows) the table has. The third function is called every time a row is created and is responsible for populating the cell with data. The fourth and fifth function are callbacks that are called when data is moved or deleted respectively.

Now if you run your application, you should see the mock data displayed. However, we cannot see the add or edit button. So let us add that functionality.

In the `viewDidLoad` function add the following lines:


    navigationItem.title = "Users List"
    navigationItem.rightBarButtonItem = self.editButtonItem
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAddUserAlertController))

In the code above, we have added two buttons, the left, and right button. The left being the add button and the right being the edit button.

In the add button, it calls a `showAddUserAlertController` method. We do not have that defined yet in our code so let us add it. Add the function below to your view controller:


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
                self.users.append(["id": self.users.count, "name" :name])
                self.tableView.reloadData()
            }
        }))
        
        present(alertCtrl, animated: true, completion: nil)
    }

The code below simply creates an alert when the add button is clicked. The alert has a `textField` and this will take the name of the user you want to add and append it to the `users` property.

Now, let us declare the `textField` property on the controller right after the class declaration:


    var textField: UITextField!

Now, we a working prototype that is not connected to any API. If you run your application at this point, you will be able to see all the functions and they will work but will not be persisted since it is hardcoded.


![](https://www.dropbox.com/s/nmoaceyxa3q0u8z/How-to-build-a-realtime-table-using-Swift-4.png?raw=1)


Great but now we need to add a data source. To do this, we will need to create a NodeJS backend and then our application will be able to call this backend to retrieve data. Also, when the data is modified by reordering or deleting, the request is sent to the backend and the changes are made to the backend.


## Adding API calls to our iOS table application

Now, let us start by retrieving the data from a remote source that we have not created yet (we will create this later in the article).

**Loading users from the API**
Go back to the `loadUsersFromApi` method and replace the contents with the following code:


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

The method above uses **Alamofire** to make calls to a `self.endpoint` and then appends the response to `self.users`. It also calls an `indicator.startAnimating()`, this is supposed to show an indicator that data is loading.

Before we create the loading indicator, let us `import Alamofire`. Under the `import UIKit` statement, add the line of code below:


    import Alamofire

That’s all! Now, let’s create the loading indicator that is already being called in the `loadUsersFromApi` function above.

First, declare the `indicator` and the `endpoint` in the class right after the controller class declaration:


    var endpoint = "http://localhost:4000"
    var indicator = UIActivityIndicatorView()

Now, create a function to initialize and configure the loading indicator. Add the function below to the controller:


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

The function above will simply set up our `UIActivityIndicatorView` which is just a spinner that indicates that our data is loading. After setting up the loading view, we then add it to the table view. 


> 💡 **We set the** `**hidesWhenStopped**` **property to** `**true**`**, this means that every time we stop the indicator using** `**stopAnimating**` **the indicator will automatically hide.**

Now, in the `viewDidLoad` function, above the call to `loadUsersFromApi`,  add the call to `setupActivityIndicator`:


    override func viewDidLoad() {
        // other stuff...
        setupActivityIndicator()
        loadUsersFromApi()
    }

Adding this before calling the `loadUsersFromApi` call will ensure the indicator has been created before it is referenced in the load users function call.

**Adding users to the API then to the table locally**
Now, let’s hook the “Add” button to our backend so that when the user is added using the textfield, a request is sent to the endpoint.

In the `showAddUserAlertController` we will make some modifications. Replace the lines below:


    if let name = self.textField.text, name != "" {
        self.users.append(["id": self.users.count, "name" :name])
        self.tableView.reloadData()
    }

with this:


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

Now in the block of code below, we are sending the request to our endpoint instead of just directly manipulating the `users` property. When the data is successful, we then append the new data to the `users` property. If you notice, however, in the `payload` we referenced `self.deviceId`, we need to create this property. Add the code below right after the class declaration:


    let deviceId = UIDevice.current.identifierForVendor!.uuidString


> 💡 **We are adding the device ID so we can differentiate who made what call to the backend and avoid manipulating the data multiple times if it was the same data that sent the request. When we integrate Pusher, the listener will be doing the same manipulations to the** `**user**` **property. However, if it’s the same device that made the request then it should skip updating the property.** 

**Moving users in the API then to the table locally**
The next thing is adding the remote move functionality. Let’s hook that up to communicate with the endpoint.

In your code, replace the function below:


    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = users[sourceIndexPath.row]
        users.remove(at: sourceIndexPath.row)
        users.insert(movedObject, at: destinationIndexPath.row)
    }

with this:


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

In the code above, we set the payload to send to the endpoint and send it using **Alamofire**. Then when we receive a successful response from the API, we make changes to the `user`  property.

**Deleting a row in the API then locally on the table**
The next thing we want to do is delete the data from the API before deleting it locally. To do this, look for the function below:


    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.users.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

and replace it with the following code below:


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

Just like the others, we have just sent the payload we generated to the API and then when there is a successful response, we delete the row from the `users` property.

Now the next thing would be to create the backend API, but before then let us add the realtime functionality into the app using Pusher.

## Adding realtime functionality to our table on iOS

Now that we are done with hooking up the API, we need to add some realtime functionality so that any other devices will pick up the changes instantly without having to reload the table manually.

First, import the Pusher SDK to your application. Under the `import Alamofire` statement, add the following:


    import PusherSwift

Now, let us declare the `pusher` property in the class right under the class declaration:


    var pusher: Pusher!

Great. Now add the function below to the controller:


    private func listenToChangesFromPusher() {
        pusher = Pusher(key: "PUSHER_APP_KEY", options: PusherClientOptions(host: .cluster("PUSHER_APP_CLUSTER")))
        
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

In this block of code, we have done quite a lot. First, we instantiate Pusher with our application’s key and cluster (replace with the one provided to you on your Pusher application dashboard). Next, we subscribed to the channel `userslist`. We will listen for events on this channel.

In the first `channel.bind` block, we bind to the `addUser` event and then when an event is picked up, the callback runs and checks for the device ID and if it is not a match, it appends the new user to the local user’s property. It does the same for the next two blocks of `channel.bind`  but in the others, it removes and moves the position respectively.

The last part is `pusher.connect` which does exactly what it says.

To listen to the changes, add the call to the bottom of the  `viewDidLoad` function:


    override func viewDidLoad() {
        // other stuff...
        listenToChangesFromPusher()
    }

That is all! We have created the realtime table that is responsive to changes received when the data is manipulated. The last part of everything is creating the backend that will be used to save the data and also to trigger Pusher events.


## Creating the Backend for our realtime iOS table

To get started, create a directory for the web application and then create some new files inside the directory:

File: **package.json**


    {
      "main": "index.js",
      "dependencies": {
        "bluebird": "^3.5.0",
        "body-parser": "^1.16.0",
        "express": "^4.14.1",
        "pusher": "^1.5.1",
        "sqlite": "^2.8.0"
      }
    }

This file will contain all the packages we intend to use to build our backend application.

Next file to create will be **config.js:**


    module.exports = {
        appId: 'PUSHER_APP_ID',
        key: 'PUSHER_APP_KEY',
        secret: 'PUSHER_APP_SECRET',
        cluster: 'PUSHER_APP_CLUSTER',
    };

This will be the location of all your configuration values. Fill the values using the data from your Pusher application’s dashboard.

Next, create an empty `database.sqlite` file in the root of your web app directory.

Next, create a directory called `migrations` inside the web application directory and inside it create the next file **001-initial-schema.sql** and paste the content below:


    -- Up
    CREATE TABLE Users (
        id INTEGER NOT NULL,
        name TEXT,
        position INTEGER NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id)
    );
    INSERT INTO Users (id, name, position) VALUES (1, 'John Doe', 1);
    -- Down
    DROP TABLE Users;

In the above, we declare the migrations to run when the application is started. 


> 💡 **The** `**-- Up**` **marks the migrations that should be run and the** `**-- Down**` **is the rollback of the migration if you want to step back and undo the migration.**

Next we will create the main file **index.js:**


    // ------------------------------------------------------
    // Import all required packages and files
    // ------------------------------------------------------
    let Pusher     = require('pusher');
    let express    = require('express');
    let bodyParser = require('body-parser');
    let Promise    = require('bluebird');
    let db         = require('sqlite');
    let app        = express();
    let pusher     = new Pusher(require('./config.js'));
    // ------------------------------------------------------
    // Set up Express
    // ------------------------------------------------------
    app.use(bodyParser.json());
    app.use(bodyParser.urlencoded({ extended: false }));
    // ------------------------------------------------------
    // Define routes and logic
    // ------------------------------------------------------
    app.get('/users', (req, res, next) => {
      try {
        // Fetch all users from the database
        db.all('SELECT * FROM (SELECT * FROM Users ORDER BY updated_at DESC) ORDER BY position ASC')
          .then(result => res.json(result))
      } catch (err) {
        next(err)
      }
    })
    app.post("/add", (req, res, next) => {
      try {
        let payload = {name:req.body.name, deviceId: req.body.deviceId}
        // Add the user to the database
        db.run("INSERT INTO Users (name, position) VALUES (?, (SELECT MAX(id) + 1 FROM Users))", payload.name).then(query => {
          payload.id = query.stmt.lastID
          pusher.trigger('userslist', 'addUser', payload)
          return res.json(payload)
        })
      } catch (err) {
        next(err)
      }
    })
    app.post("/delete", (req, res, next) => {
      try {
        let payload = {id:parseInt(req.body.id), index:parseInt(req.body.index), deviceId: req.body.deviceId}
        // Delete the user from the database
        db.run(`DELETE FROM Users WHERE id=${payload.id}`).then(query => {
          pusher.trigger('userslist', 'removeUser', payload)
          return res.json(payload)
        })
      } catch (err) {
        next(err)
      }
    })
    app.post("/move", (req, res, next) => {
      try {
        let payload = {
          deviceId: req.body.deviceId,
          src: parseInt(req.body.src),
          dest: parseInt(req.body.dest),
          src_id: parseInt(req.body.src_id),
          dest_id: parseInt(req.body.dest_id),
        }
        // Update the position of the user
        db.run(`UPDATE Users SET position=${payload.dest + 1}, updated_at=CURRENT_TIMESTAMP WHERE id=${payload.src_id}`).then(query => {
          pusher.trigger('userslist', 'moveUser', payload)
          res.json(payload)
        })
      } catch (err) {
        next(err)
      }
    })
    app.get('/', (req, res) => {
      res.json("It works!");
    });
    
    // ------------------------------------------------------
    // Catch errors
    // ------------------------------------------------------
    app.use((req, res, next) => {
        let err = new Error('Not Found');
        err.status = 404;
        next(err);
    });
    
    // ------------------------------------------------------
    // Start application
    // ------------------------------------------------------
    Promise.resolve()
      .then(() => db.open('./database.sqlite', { Promise }))
      .then(() => db.migrate({ force: 'last' }))
      .catch(err => console.error(err.stack))
      .finally(() => app.listen(4000, function(){
        console.log('App listening on port 4000!')
      }));
    

In the code above, we loaded all the required packages including Express and Pusher. After instantiating them, we create the routes we need.

The routes are designed to do pretty basic things like add row from the database, delete a row from the database, update rows in the database. For the database, we are using the [SQLite NPM package](https://www.npmjs.com/package/sqlite).

In the last block, we migrate the database using the `/migrations/001-initial-schema.sql` file into the `database.sqlite`  file. Then we start the express application after everything is done.

Now open the terminal and `cd` to the root of the web application directory and run the commands below to install the NPM dependencies and run the application respectively:


    $ npm install
    $ node index.js

When the installation is complete and the application is ready you should see the message **App listening on port 4000!**


## Testing the application

Once you have your local node web server running, you will need to make some changes so your application can talk to the local web server. In the `info.plist` file, make the following changes:


![](https://www.dropbox.com/s/e8wuutr07ithe4d/How-to-build-a-realtime-table-using-Swift-5.png?raw=1)


With this change, you can build and run your application and it will talk directly with your local web application.


## Conclusion

This article has demonstrated how you can create tables in iOS that respond in realtime to changes made on other devices. This is very useful and can be applied to data that has to be updated dynamically and instantly across all devices.

If you have any questions, feedback or corrections, you can post them in the comments section below.

The source code to the tutorial above is available on [GitHub](https://github.com/neoighodaro/Build-a-realtime-table-using-Swift).

