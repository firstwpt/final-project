//
//  SignInController.swift
//  final_project
//
//  Created by Nantanat Thongthep on 3/12/2564 BE.
//

import UIKit
import GoogleSignIn
import GRDB

class SignInVC: UIViewController {
    
    //textField & validationDescLabel
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!

    @IBOutlet weak var emailDesc: UILabel!
    @IBOutlet weak var passDesc: UILabel!

    var validatorType: TextFieldValidatorType! = .None

    //sign in with google
    @IBOutlet weak var signInGoogle: UIButton!
    
    let signInConfig = GIDConfiguration.init(clientID: "629469457357-8ra2vg115qg2g1kflu2di04f83he5eet.apps.googleusercontent.com")
    
    //database
    var dbPath : String = ""
    var dbResourcePath : String = ""
    var config = Configuration()
    let fileManager = FileManager.default
    
    //session
    var defaults = UserDefaults.standard
    var userData = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInterface()
        connect2DB()
    }
    
    // MARK: - Interface
    
    func setInterface() {
        signInGoogle.layer.cornerRadius = 6
        signInGoogle.layer.borderWidth = 1
        signInGoogle.layer.borderColor = UIColor.lightGray.cgColor
        
        emailDesc.text = " "
        passDesc.text = " "
    }
    
    // MARK: - Action
    
    @IBAction func signInWithGoogle(_ sender: Any) {
        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: self) { user, error in
            guard error == nil else { return }
            guard let user = user else { return }
            
            let emailAddress = user.profile?.email
            
            self.selectQuery(user_email: emailAddress!, user_password: "email")
            self.changeView("signInWithGoogle")
        }
    }
    
    @IBAction func textFieldDidEndEditing(_ textField: UITextField) {
        checkTextFieldType(textField)
    }
    
    @IBAction func textFieldDidTextChange(_ textField: UITextField) {
        checkTextFieldType(textField)
    }
    
    @IBAction func signIn(_ sender: Any) {
        if textFieldisComplete() {
            selectQuery(user_email: emailTextField.text!, user_password: passTextField.text!)
            changeView("signIn")
        }
        else {
            alert()
        }
    }
    
    @IBAction func signUp(_ sender: Any) {
        changeView("signUp")
    }
    
    
    // MARK: - Validator
    
    func checkTextFieldType(_ textField: UITextField) {
        let tag = textField.tag
        
        switch tag {
        case 0:
            validatorType = .Email
            validate(textField, tag)
        case 1:
            validatorType = .Password
            validate(textField, tag)
        default:
            validatorType = .None
        }
    }
    
    func validate(_ textField: UITextField, _ textFieldTag: Int) {
        guard let text = textField.text else { return }
        let validatedText = validatorType.validate(text)
        let result = validatedText.result
        
        switch textFieldTag {
        case 0:
            validateHandler(result, textField, emailDesc, validatedText.desc)
        case 1:
            validateHandler(result, textField, passDesc, validatedText.desc)
        default:
            print("Something went wrong")
        }
    }
    
    func textFieldisComplete() -> Bool {
        var isComplete = true
        
        if emailTextField.text!.isEmpty || emailTextField.layer.borderColor == UIColor.red.cgColor {
            isComplete = false
        }
        if passTextField.text!.isEmpty || passTextField.layer.borderColor == UIColor.red.cgColor {
            isComplete = false
        }
        return isComplete
    }
    
    // MARK: - Handler
    
    func validateHandler(_ isSucceeded: Bool, _ textField: UITextField, _ validationDescLabel: UILabel, _ desc: String) {
        if isSucceeded {
            textField.layer.borderColor = #colorLiteral(red: 0.8000000119, green: 0.8000000119, blue: 0.8000000119, alpha: 1)
        }
        else {
            textField.layer.borderColor = UIColor.red.cgColor
        }
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 5
        validationDescLabel.text = desc
    }
    
    func alert() {
        let alertVC = UIAlertController(title: "Error", message: "Please fill up the form", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alertVC, animated: true, completion: nil)
    }
    
    // MARK: - Store Data
    
    func insert2AR(firstname: String, lastname: String, email: String, password: String) {
        userData.insert(firstname, at: 0)
        userData.insert(lastname, at: 1)
        userData.insert(email, at: 2)
        userData.insert(password, at: 3)
        defaults.set(userData, forKey: "savedUser")
    }
    
    // MARK: - Database
    
    func connect2DB() {
        config.readonly = true
        do {
            dbPath = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("final_project.sqlite")
                .path
            if !fileManager.fileExists(atPath: dbPath) {
                dbResourcePath = Bundle.main.path(forResource: "final_project", ofType: "sqlite")!
                try fileManager.copyItem(atPath: dbResourcePath, toPath: dbPath)
            }
        } catch {
            print("An error has occured")
        }
    }
    
    func selectQuery(user_email: String, user_password: String) {
        do {
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
            try dbQueue.inDatabase { db in
                
                let valid_both = try Row.fetchCursor(db, sql: "SELECT user_firstname, user_lastname, user_email, user_password FROM user WHERE user_email = (?) AND user_password = (?)", arguments: [user_email, user_password])
                
                let valid_email = try Row.fetchCursor(db, sql: "SELECT user_firstname, user_lastname, user_email, user_password FROM user WHERE user_email = (?)", arguments: [user_email])
                
                let valid_password = try Row.fetchCursor(db, sql: "SELECT user_firstname, user_lastname, user_email, user_password FROM user WHERE user_password = (?)", arguments: [user_password])
                
                while let row = try valid_both.next() {
                    insert2AR(firstname: row["user_firstname"], lastname: row["user_lastname"], email: row["user_email"], password: row["user_password"])
                    changeView("signIn")
                }
                
                while let _ = try valid_email.next() {
                    validateHandler(false, passTextField, passDesc, "The password is incorrect")
                }
                
                while let _ = try valid_password.next() {
                    validateHandler(false, emailTextField, emailDesc, "Couldn't find your email")
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Change View
    
    func changeView(_ button: String) {
        if userData.count == 4 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let navigationView = storyboard.instantiateViewController(withIdentifier: "navigationView")
            
            self.view.window?.rootViewController = navigationView
        }
        if button == "signUp" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let signUpView = storyboard.instantiateViewController(withIdentifier: "signUpView") as! SignUpVC
            
            self.view.window?.rootViewController = signUpView
        }
    }
}

extension SignInVC {
    
    enum TextFieldValidatorType {
        case Password
        case Email
        case None
        
        func validate(_ text: String) -> (result: Bool, desc: String) {
            switch self {
            case .Password:
                if (text.count < 8) {
                    return (false, "Password must longer than 8 characters")
                } else if (text.count > 16) {
                    return (false, "Password must not longer than 16 characters")
                } else if (text.hasSpecialCharacters()) {
                    return (false, "Password cannot contain any special character")
                }
                return (true, "")
    
            case .Email:
                if (!text.isEmailFormat()) {
                    return (false, "Invalid email format")
                }
                return (true, "")
                
            case .None:
                return (false, "Something went wrong")
            }
        }
    }
}
