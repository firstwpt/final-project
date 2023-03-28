//
//  TimePicker.swift
//  final_project
//
//  Created by Nantanat Thongthep on 5/12/2564 BE.
//

import UIKit

class TimePicker: UIViewController {

    @IBOutlet weak var showTime: UITextField!
    let timePicker = UIDatePicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let toolbar = UIToolbar()
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButton))
        toolbar.sizeToFit()
        toolbar.items = [doneBtn]
        showTime.inputAccessoryView = toolbar
        
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        showTime.inputView = timePicker
    }
    
    @objc func doneButton() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        showTime.text = formatter.string(from: timePicker.date)
        self.view.endEditing(true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
