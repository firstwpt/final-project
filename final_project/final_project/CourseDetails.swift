//
//  Course.swift
//  final_project
//
//  Created by Nantanat Thongthep on 5/12/2564 BE.
//

import Foundation
import UIKit

class Course {
    var name: String?
    var lecturer: String?
    var day: String?
    var courseColor: UIColor?
    var dayColor: UIColor?
    
    public init(name: String, lecturer: String, day: String, courseColor: UIColor, dayColor: UIColor) {
        self.name = name
        self.lecturer = lecturer
        self.day = day
        self.courseColor = courseColor
        self.dayColor = dayColor
    }
}
