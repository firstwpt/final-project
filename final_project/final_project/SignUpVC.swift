//
//  ViewController.swift
//  final_project
//
//  Created by Nantanat Thongthep on 2/12/2564 BE.
//

import UIKit
import GoogleSignIn
import GRDB

class SignUpVC: UIViewController {
    
    //textField & validationDescLabel
    @IBOutlet weak var firstnameTextField: UITextField!
    @IBOutlet weak var lastnameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var conpassTextField: UITextField!

    @IBOutlet weak var nameDesc: UILabel!
    @IBOutlet weak var emailDesc: UILabel!
    @IBOutlet weak var passDesc: UILabel!
    @IBOutlet weak var conpassDesc: UILabel!

    var validatorType: TextFieldValidatorType! = .None

    //sign up with google
    @IBOutlet weak var signUpGoogle: UIButton!
    var existsGmail: Bool = false
    let signInConfig = GIDConfiguration.init(clientID: "629469457357-8ra2vg115qg2g1kflu2di04f83he5eet.apps.googleusercontent.com")
    
    //session
    var userData = [String]()
    var defaults = UserDefaults.standard
    
    //database
    var dbPath : String = "" //file db
    var dbResourcePath : String = "" //เช็คไฟล์ว่ามีอยู่มั้ย
    var config = Configuration() //จัดการ สักอย่าง;-;
    let fileManager = FileManager.default //ตัวกลางระหว่าง dbPath n คอมไพเลอร์ ให้คุยกันรู้เรื่อง
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInterface()
        connect2DB()
    }
    
    // MARK: - Interface
    
    func setInterface() {
        signUpGoogle.layer.cornerRadius = 6 //เลขยิ่งสูง มุมยิ่งโค้ง
        signUpGoogle.layer.borderWidth = 1 //ความกว้างของเส้น
        signUpGoogle.layer.borderColor = UIColor.lightGray.cgColor //สีเส้น
        
        nameDesc.text = " "
        emailDesc.text = " "
        passDesc.text = " "
        conpassDesc.text = " "
    }
    
    // MARK: - Action
    
    @IBAction func signUpWithGoogle(_ sender: Any) {
        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: self) { user, error in
            guard error == nil else { return }
            guard let user = user else { return }
            
//            let fullName = user.profile?.name
//            let profilePicUrl = user.profile?.imageURL(withDimension: 320)
            let givenName = user.profile?.givenName
            let familyName = user.profile?.familyName
            let emailAddress = user.profile?.email
            
            self.selectQuery(user_email: emailAddress!, "Sign up with google")
            //ส่งค่าผ่านตัวแปรนี้ existGmail
            if !self.existsGmail {
                //เก็บข้อมูล user ใน array(insrt2AR)
                self.insert2AR(firstname: givenName!, lastname: familyName!, email: emailAddress!, password: "email")
                self.insertQuery() //เข้า db
                self.changeView("signUpwithGoogle") //เปลี่ยนหน้า
            }
        }
    }
    
    //ทำงานตอน user กรอกเสร็จแล้ว
    //select จาก db มาเช็คว่ามันมีใน db มั้ย
    @IBAction func textFieldDidEndEditing(_ textField: UITextField) {
        checkTextFieldType(textField)
        selectQuery(user_email: emailTextField.text!, "Sign Up")
    }
    
    //ทำตอน user กรอกข้อมูล -> เช็คเลย
    @IBAction func textFieldDidTextChange(_ textField: UITextField) {
        checkTextFieldType(textField)
    }
    
    @IBAction func signUp(_ sender: Any) {
        //เช็ตว่าสมบูรณ์รึยัง
        if textFieldisComplete() {
            insert2AR(firstname: firstnameTextField.text!, lastname: lastnameTextField.text!, email: emailTextField.text!, password: passTextField.text!)
            insertQuery() //เก็บใน array
            changeView("signUp") //เปลี่ยนหน้า
        }
        //ถ้ายังไม่สมบูรณ์ แจ้ง alert
        else {
            alert("Please fill up this form")
        }
    }
    
    @IBAction func signIn(_ sender: Any) {
        changeView("signIn")
    }
    
    // MARK: - Validator
    
    func checkTextFieldType(_ textField: UITextField) {
        let tag = textField.tag
    
        switch tag {
        case 0:
            validatorType = .Firstname //เช็ครูปแบบ input
            validate(textField, tag) //ส่งไปจัดการ error
        case 1:
            validatorType = .Lastname
            validate(textField, tag)
        case 2:
            validatorType = .Email
            validate(textField, tag)
        case 3:
            validatorType = .Password
            validate(textField, tag)
        case 4:
            validate(textField, tag)
        default:
            validatorType = .None
        }
    }
    
    func validate(_ textField: UITextField, _ textFieldTag: Int) {
        guard let text = textField.text else { return }
        //เช็ค/ส่งข้อความที่กรอก
        let validatedText = validatorType.validate(text)
        let result = validatedText.result
        
        switch textFieldTag {
        case 0:
            validateHandler(result, textField, nameDesc, validatedText.desc)
        case 1:
            validateHandler(result, textField, nameDesc, validatedText.desc)
        case 2:
            validateHandler(result, textField, emailDesc, validatedText.desc)
        case 3:
            validateHandler(result, textField, passDesc, validatedText.desc)
        case 4:
            if (text != passTextField.text) {
                validateHandler(false, textField, conpassDesc, "Passwords do not match")
            } else {
                validateHandler(true, textField, conpassDesc, " ")
            }
        default:
            print("Something went wrong")
        }
    }
    
    //เช็คค่าว่าง & ถูกต้องมั้ย
    func textFieldisComplete() -> Bool {
        var isComplete = true
        
        if firstnameTextField.text!.isEmpty || firstnameTextField.layer.borderColor == UIColor.red.cgColor {
            isComplete = false
        }
        if lastnameTextField.text!.isEmpty || lastnameTextField.layer.borderColor == UIColor.red.cgColor {
            isComplete = false
        }
        if emailTextField.text!.isEmpty || emailTextField.layer.borderColor == UIColor.red.cgColor {
            isComplete = false
        }
        if passTextField.text!.isEmpty || passTextField.layer.borderColor == UIColor.red.cgColor {
            isComplete = false
        }
        if conpassTextField.text!.isEmpty || conpassTextField.layer.borderColor == UIColor.red.cgColor {
            isComplete = false
        }
        return isComplete
    }
    
    // MARK: - Error Handler
    
    //จัดการกับ error เฉย ๆ
    func validateHandler(_ isSucceeded: Bool, _ textField: UITextField, _ validationDescLabel: UILabel, _ desc: String) {
        //ถ้าถูก = ไม่เปลี่ยนสี
        if isSucceeded {
            textField.layer.borderColor = #colorLiteral(red: 0.8000000119, green: 0.8000000119, blue: 0.8000000119, alpha: 1)
        }
        //ถ้าไม่ถูก = เปลี่ยนขอบเป็นสีแดง
        else {
            textField.layer.borderColor = UIColor.red.cgColor
        }
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 5
        validationDescLabel.text = desc
    }
    
    //ถ้า user เคยสมัครแล้วให้แจ้ง
    func alert(_ message: String) {
        let alertVC = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alertVC, animated: true, completion: nil)
    }
    
    // MARK: - Store Data
    
    //เก็บค่าใน array -> userData -> dafaults
    func insert2AR(firstname: String, lastname: String, email: String, password: String) {
        userData.insert(firstname, at: 0)
        userData.insert(lastname, at: 1)
        userData.insert(email, at: 2)
        userData.insert(password, at: 3)
        defaults.set(userData, forKey: "savedUser")
    }
        
    // MARK: - Database
    
    //fileManager เป็นสื่อกลาง เก็บค่าใน dbPath
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
    
    func insertQuery() {
        do {
            config.readonly = false
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
            
            try dbQueue.write {
                db in
                try db.execute(sql: "INSERT INTO user (user_firstname, user_lastname, user_email, user_password) VALUES (?, ?, ?, ?)", arguments: [userData[0], userData[1], userData[2], userData[3]])
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //ถ้ามีบัญชีอยู่ให้แจ้ง
    //sign up กับเราให้แจ้ง?
    func selectQuery(user_email: String, _ action: String) {
        do {
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
            try dbQueue.inDatabase { db in
                
                let rows = try Row.fetchCursor(db, sql: "SELECT user_email FROM user WHERE user_email = (?)", arguments: [user_email])
                
                while let _ = try rows.next() {
                    if action == "Sign up with google" {
                        existsGmail = true
                        alert("Email already exists")
                    } else {
                        validateHandler(false, emailTextField, emailDesc, "Email already exists")
                    }
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
        if button == "signIn" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let signInView = storyboard.instantiateViewController(withIdentifier: "signInView") as! SignInVC
            
            self.view.window?.rootViewController = signInView
        }
    }
}

extension SignUpVC {
    
    enum TextFieldValidatorType {
        case Password
        case Email
        case Firstname
        case Lastname
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
                
            case .Firstname:
                if (text.count < 2) {
                    return (false, "Your name must longer than 1 characters")
                } else if (!text.isCharacter()) {
                    return (false, "Only character is allowed")
                }
                return (true, "")
                
            case .Lastname:
                if (text.count < 2) {
                    return (false, "Your name must longer than 1 characters")
                } else if (!text.isCharacter()) {
                    return (false, "Only character is allowed")
                }
                return (true, "")
                
            case .None:
                return (false, "Something went wrong")
            }
        }
    }
}

