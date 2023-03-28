//
//  addCourseVC.swift
//  final_project
//
//  Created by Nantanat Thongthep on 5/12/2564 BE.
//

import UIKit
import GRDB

class addCourseVC: UIViewController {
    
    //ประกาศตัวแปรไว้รับค่าข้อมูล
    //ui
    @IBOutlet weak var coursename: UITextField!
    @IBOutlet weak var lecturer: UITextField!
    @IBOutlet weak var classType: UITextField!
    @IBOutlet weak var classLocation: UITextField!
    @IBOutlet weak var studyDay: UITextField!
    @IBOutlet weak var studyStartTime: UITextField!
    @IBOutlet weak var studyEndTime: UITextField!
    @IBOutlet weak var courseColor: UITextField!
    
    @IBOutlet weak var courseDescLabel: UILabel!
    @IBOutlet weak var lectDescLabel: UILabel!
    @IBOutlet weak var stuDayDescLabel: UILabel!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    let timePicker = UIDatePicker() //ไว้โชว์เวลาขึ้นมาเลือกได้
    
    //ตัวแปรเก็บค่า days colors และ course_id ให้เริ่มต้นที่ 1
    //init data
    var days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    var colors = ["Orange", "Blue", "Brown", "Green", "Purple", "Red", "Pink", "Yellow"]
    var course_id = "1"
    
    //ตัวแปรรับค่าจากหน้า CoursesVC
    //from CoursesVC
    var actionFromCourseVC = " "
    var courseDetails = [String]()
    
    
    //session
    var userData = [String]()
    var defaults = UserDefaults.standard
    
    //database
    var dbPath : String = ""
    var dbResourcePath : String = ""
    var config = Configuration()
    let fileManager = FileManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInterface() //ตั้งค่าหน้า UI เริ่มต้น ว่าเวลาเปิดขึ้นมาให้เป็นยังไง
        useSession() //ดึงข้อมูล user มาใช้
        connect2DB() //เชื่อมกับ db
        selectQuery() //ดึงข้อมูลจาก db มาใช้
    }
    
    // MARK: - Interface
    
    //ตั้งค่าหน้า UI เริ่มต้น ว่าเวลาเปิดขึ้นมาให้เป็นยังไง
    func setInterface() {
    //ให้สามตัวนี้เป็นค่าว่าง ?
        courseDescLabel.text = " "
        lectDescLabel.text = " "
        stuDayDescLabel.text = " "
        
        //ถ้ามีกดแถวไหน ก็ให้เก็บใน array นั้นๆ ?
        //ถ้ากดมาจากคอร์สที่มีอยู่แล้ว คือกดเข้ามาแก้ ก็ใช้โชว์ตามที่เคยใส่ไว้
        if actionFromCourseVC == "didSelectRow" {
            deleteButton.isHidden = false
            coursename.text = courseDetails[1]
            lecturer.text = courseDetails[2]
            studyDay.text = courseDetails[3]
            studyStartTime.text = courseDetails[4]
            studyEndTime.text = courseDetails[5]
            classType.text = courseDetails[6]
            classLocation.text = courseDetails[7]
            courseColor.text = courseDetails[8]
        }
    }
    
    //ดึงข้อมูล user มาใช้
    func useSession() {
        self.userData = defaults.object(forKey: "savedUser") as! [String]
    }
    
    // MARK: - Action
    
    //
    @IBAction func textFieldTouchDown(_ textField: UITextField) {
        sendToErrorHandler(textField) //ส่งไปเช็ค error
        sendToSetPicker(textField) //ส่ง tag
    }
    
    //ให้ไปดู error
    @IBAction func textFieldDidTextChange(_ textField: UITextField) {
        sendToErrorHandler(textField)
    }
    
    //ให้เปลี่ยนไปหน้า CoursesVC
    @IBAction func cancelButton(_ sender: Any) {
        changeView()
    }
    
    
    @IBAction func doneButton(_ sender: Any) {
        //ถ้ามีปุ่ม delete ขึ้นมา หมายถึงให้อัพเดตข้อมูลหรือลบ
        guard deleteButton.isHidden else {
            updateQuery() //update ข้อมูล
            changeView() //เปลี่ยนไปหน้า CoursesVC
            return
        }
        
        //ถ้า textField ว่าง ให้แจ้ง error
        if textFieldisEmpty() {
            validateHandler(isEmpty: true, coursename, courseDescLabel)
            validateHandler(isEmpty: true, lecturer, lectDescLabel)
            validateHandler(isEmpty: true, studyDay, stuDayDescLabel)
        } else {
            insertQuery() //เพิ่มข้อมูลเข้าไปใน array
            changeView() //เปลี่ยนไปหน้า CoursesVC
        }
    }

    //ถ้ากด delete
    @IBAction func deleteButton(_ sender: Any) {
        deleteQuery() //ลบข้อมูล
        changeView() //เปลี่ยนไปหน้า CoursesVC
    }
    
    // MARK: - Picker
    
    //เป็น picker มีการใส่ tag ไว้ด้วย
    func setPicker(_ textField: UITextField, tag: Int) {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        textField.inputView = picker
        picker.tag = tag
    }
    
    //ให้แถบขึ้นมา ???
    func setBarButton(_ textField: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit() //พอดีกับตัวโทรศัพท์
        
        //เป็นปุ่มไว้กดตอนเลือกข้อมูลเสร็จ
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDay))
        toolbar.setItems([doneButton], animated: true)
        toolbar.isUserInteractionEnabled = true
        textField.inputAccessoryView = toolbar
    }
    
    @objc func doneDay() {
        self.view.endEditing(true)
    }
    
    // Time Picker
    
    //picker เลือกเวลา
    func setTimePicker(_ timeTextField: UITextField, _ doneButton: UIBarButtonItem) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [doneButton]
        timeTextField.inputAccessoryView = toolbar
    
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels //ใช้ wheels (วิลส์) แบ่งเป็นสามช่อง
        timeTextField.inputView = timePicker
    }
    
    //เวลาเริ่มเรียน
    @objc func doneStartTime() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        studyStartTime.text = formatter.string(from: timePicker.date)
        self.view.endEditing(true)
    }
    
    //เวลาเลิกเรียน
    @objc func doneEndTime() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        studyEndTime.text = formatter.string(from: timePicker.date)
        self.view.endEditing(true)
    }
    
    // MARK: - Picker Handler
    
    func sendToSetPicker(_ textField: UITextField) {
        let tag = textField.tag
        
        switch tag {
        case 2: //วันที่เรียน
            setPicker(studyDay, tag: 2)
            setBarButton(studyDay)
        case 3: //เวลาเริ่มเรียน
            let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneStartTime))
            setTimePicker(textField, button)
        case 4: //เวลาเลิกเรียน
            let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneEndTime))
            setTimePicker(textField, button)
        case 7: //สีของ course
            setPicker(courseColor, tag: 7)
            setBarButton(courseColor)
        default:
            break
        }
    }
    
    // MARK: - Validator
    
    //เช็คค่าว่าง ถ้ามีค่าว่างก็จะให้แจ้ง error
    //ถ้ามีว่างก็จะให้ text เปลี่ยนเป็นสีส้ม ???
    func textFieldisEmpty() -> Bool {
        if coursename.text!.isEmpty { return true }
        if lecturer.text!.isEmpty { return true }
        if studyDay.text!.isEmpty { return true }
        if courseColor.text!.isEmpty { courseColor.text = "Orange" }
        
        return false
    }
    
    //ส่งประเภท ? หรือ tag ?
    func sendToErrorHandler(_ textField: UITextField) {
        let tag = textField.tag

        switch tag {
        case 0:
            validateHandler(isEmpty: false, textField, courseDescLabel)
        case 1:
            validateHandler(isEmpty: false, textField, lectDescLabel)
        case 2:
            validateHandler(isEmpty: false, textField, stuDayDescLabel)
        default:
            break
        }
    }
    
    // MARK: - Error Handler
    
    //จัดการ error เฉยๆ ไม่เกี่ยวกับหน้า UI
    func validateHandler(isEmpty: Bool, _ textField: UITextField, _ descLabel: UILabel) {
        if isEmpty {
            textField.layer.borderColor = UIColor.red.cgColor //เปลี่ยนขอบเป็นสีแดง
            descLabel.text = "Please fill in the form" //โชว์ข้อความ
        } else {
            textField.layer.borderColor = #colorLiteral(red: 0.8775331378, green: 0.8775331378, blue: 0.8775331378, alpha: 1)
            descLabel.text = " "
        }
        //ขนาดของ textfield
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 5
    }
    
    // MARK: - Database
    
    func connect2DB() {
        config.readonly = true //อ่านอย่างเดียว = true
        do {
            //ชี้ไปยังตำแหน่งของตัวไฟล์
            dbPath = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("final_project.sqlite")
                .path
            //ตรวจสอบว่ามีไฟล์อยู่จริงรึเปล่า
            if !fileManager.fileExists(atPath: dbPath) {
                dbResourcePath = Bundle.main.path(forResource: "final_project", ofType: "sqlite")!
                try fileManager.copyItem(atPath: dbResourcePath, toPath: dbPath)
            }
        } catch {
            print("An error has occured")
        }
    }
    
    //ดึงข้อมูลใน db มาใช้
    func selectQuery() {
        do {
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
            try dbQueue.inDatabase { db in

                let rows = try Row.fetchCursor(db, sql: "SELECT course_id FROM course")

                while let row = try rows.next() {
                    if course_id == row["course_id"] {
                        course_id = String(Int(course_id)! + 1)
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    //เพิ่มข้อมูลใน db
    func insertQuery() {
        do {
            config.readonly = false
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

            try dbQueue.write {
                db in
                try db.execute(sql: "INSERT INTO course (course_id, user_email, course_name, course_lecturer, course_day, course_startTime, course_endTime, course_type, course_location, course_color) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", arguments: [course_id, userData[2], coursename.text!, lecturer.text!, studyDay.text!, studyStartTime.text!, studyEndTime.text!, classType.text!, classLocation.text!, courseColor.text!])
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //ลบข้อมูลใน db
    func deleteQuery() {
        do {
            config.readonly = false
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

            try dbQueue.write {
                db in
                try db.execute(sql: "DELETE FROM course WHERE course_id = (?)", arguments: [courseDetails[0]])
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //update ข้อมูลใน db
    func updateQuery() {
        do {
            config.readonly = false
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

            try dbQueue.write {
                db in
                try db.execute(sql: "UPDATE course SET course_name = (?), course_lecturer = (?), course_day = (?), course_startTime = (?), course_endTime = (?), course_type = (?), course_location = (?), course_color = (?) WHERE course_id = (?)", arguments: [coursename.text!, lecturer.text!, studyDay.text!, studyStartTime.text!, studyEndTime.text!, classType.text!, classLocation.text!, courseColor.text!, courseDetails[0]])
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Change View
    
    //เปลี่ยนหน้า
    func changeView() {
        self.dismiss(animated: true, completion: nil)
    }
}

//
extension addCourseVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 2:
            return days.count //แสดงจำนวน days
        case 7:
            return colors.count
        default:
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 2:
            return days[row] //แสดงข้อมูล row ใน days
        case 7:
            return colors[row]
        default:
            return "Data not found"
        }
    }
    
    //โชว์เป็น text อันที่เลือก ???
    //หรือโชว์ข้อมูลในแถว ?
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 2:
            studyDay.text = days[row] //โชว์ข้อมูลใน row นั้น ๆ ใน text
        case 7:
            courseColor.text = colors[row]
        default:
            return
        }
    }
    
}
