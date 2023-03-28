//
//  CouresCellController.swift
//  final_project
//
//  Created by Nantanat Thongthep on 5/12/2564 BE.
//

import UIKit

class CouresCellVC: UITableViewCell {
    
    @IBOutlet weak var colorCourseView: UIView!
    @IBOutlet weak var courseNameLabel: UILabel!
    @IBOutlet weak var lecturerLabel: UILabel!
    @IBOutlet weak var studyDayLabel: UILabel!
    @IBOutlet weak var studyDayView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        colorCourseView.layer.cornerRadius = 8
        studyDayView.layer.cornerRadius = 6
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
