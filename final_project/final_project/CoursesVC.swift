//
//  CoursesController.swift
//  final_project
//
//  Created by Nantanat Thongthep on 4/12/2564 BE.
//

import UIKit
import GRDB

class CoursesVC: UIViewController, UISearchBarDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var courseTableView: UITableView!
    let searchController = UISearchController() //ตั้งไว้ค่อยเรียกใข้
    
    //store data
    var course_id = [String]()
    var course_name = [String]()
    var course_lecturer = [String]()
    var course_day = [String]()
    var course_startTime = [String]()
    var course_endTime = [String]()
    var course_type = [String]()
    var course_location = [String]()
    var course_color = [String]()
    var courses = [Course]() //[Course]() = ประกาศเป็น class ไว้แล้วค่อยเรียกมาใช้
    var filteredCourses = [Course]() //กรอง course ถ้า search แล้วตรงกันก็โชว์ชื่อเฉพาะที่ user ต้องการ search
    
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
        setSearchController()
        setSession()
        connect2DB()
        selectQuery()
        appendCourseDetails() //CourseDetails() = course
    }
    
    //life(?)cycle
    //ทำเมื่อหน้านี้ (course) เปิดมา ทุกครั้ง
    override func viewWillAppear(_ animated: Bool) {
        clearOldData() //clear ก่อน เพื่อไม่ให้ข้อมูลซ้ำ
        connect2DB() //แล้วค่อยดึงกลับมาใช้ใหม่
        selectQuery()
        appendCourseDetails()
        updateSearchResults(for: searchController) //เหมือน refresh หน้า
        courseTableView.reloadData() //เหมือน refresh หน้า
    }

    // MARK: - Interface
    
    func setSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false //ตั้งเป็น false เพืื่อเวลาสกอเมาส์แล้ว searchBar จะไม่หายไป
        searchController.searchResultsUpdater = self //รู้ว่า user พิมพ์อะไร
        searchController.searchBar.delegate = self
        searchController.searchBar.scopeButtonTitles = ["All", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        //คล้าย ๆ secment แต่มันมากับ searchBar
        
        //ความสูง
        courseTableView.rowHeight = 76
    }
    
    //ดึงข้อมูลจาก dafaults เก็บใน userData
    func setSession() {
        self.userData = defaults.object(forKey: "savedUser") as! [String]
    }
    
    //clear เป็นค่าว่าง ให้เหมือนเริ่มใหม่อีกครั้งนึง
    func clearOldData() {
        course_id = [String]()
        course_name = [String]()
        course_lecturer = [String]()
        course_day = [String]()
        course_startTime = [String]()
        course_endTime = [String]()
        course_type = [String]()
        course_location = [String]()
        course_color = [String]()
        courses = [Course]()
        filteredCourses = [Course]()
    }
    
    // MARK: - Action
    
    @IBAction func addCourse(_ sender: Any) {
        changeView("addCourse", index: -1)
    }
    
    // MARK: - Table View
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive {
            return filteredCourses.count
        }
        return courses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "courseCell", for: indexPath) as! CouresCellVC
        let course: Course?
      
        if searchController.isActive {
            course = filteredCourses[indexPath.row]
        } else {
            course = courses[indexPath.row]
        }
        
        cell.colorCourseView?.backgroundColor = course?.courseColor
        cell.courseNameLabel?.text = course?.name
        cell.lecturerLabel?.text = course?.lecturer
        cell.studyDayLabel?.text = course?.day
        cell.studyDayView?.backgroundColor = course?.dayColor
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        changeView("didSelectRow", index: indexPath.row)
    }
    
    // MARK: - Search Bar
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scopeButton = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        guard let searchText = searchBar.text else { return }
        filterSearch(searchText, scopeButton)
    }
    
    func filterSearch(_ searchText: String, _ scopeButton: String) {
        //filter กรองใน courses
        filteredCourses = courses.filter { course in
            let scopeMatch = scopeButton == "All" || course.day!.lowercased().contains(scopeButton.lowercased())
            
            if !searchText.isEmpty {
                let searchTextMatch = course.name!.lowercased().contains(searchText.lowercased())
                return scopeMatch && searchTextMatch
            } else {
                return scopeMatch
            } 
        }
        courseTableView.reloadData()
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

    func selectQuery() {
        do {
            let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
            try dbQueue.inDatabase { db in

                let rows = try Row.fetchCursor(db, sql: "SELECT course_id, course_name, course_lecturer, course_day, course_startTime, course_endTime, course_type, course_location, course_color FROM course WHERE user_email = (?)", arguments: [userData[2]])

                while let row = try rows.next() {
                    course_id.append(row["course_id"])
                    course_name.append(row["course_name"])
                    course_lecturer.append(row["course_lecturer"])
                    course_day.append(row["course_day"])
                    course_startTime.append(row["course_startTime"])
                    course_endTime.append(row["course_endTime"])
                    course_type.append(row["course_type"])
                    course_location.append(row["course_location"])
                    course_color.append(row["course_color"])
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Format Data Type
    
    func colorOfCourse(_ index: Int) -> UIColor {
        let text = course_color[index]
        var selectedColor: UIColor = .orange
        
        switch text {
        case "Orange":
            selectedColor = .orange
        case "Blue":
            selectedColor = .blue
        case "Brown":
            selectedColor = .brown
        case "Green":
            selectedColor = .green
        case "Purple":
            selectedColor = .purple
        case "Red":
            selectedColor = .red
        case "Pink":
            selectedColor = .systemPink
        case "Yellow":
            selectedColor = .yellow
        default:
            selectedColor = .orange
        }
        return selectedColor
    }
    
    func colorOfDay(_ index: Int) -> UIColor {
        let day = course_day[index]
        var dayColor: UIColor
        
        switch day {
        case "Mon":
            dayColor = .systemYellow
        case "Tue":
            dayColor = .systemPink
        case "Wed":
            dayColor = .systemGreen
        case "Thu":
            dayColor = .systemOrange
        case "Fri":
            dayColor = .systemBlue
        case "Sat":
            dayColor = .systemPurple
        case "Sun":
            dayColor = .systemRed
        default:
            dayColor = .systemYellow
        }
        return dayColor
    }
    
    // MARK: - Store Data

    func appendCourseDetails() {
        for i in 0..<course_name.count {
            courses.append(Course(name: course_name[i], lecturer: course_lecturer[i], day: course_day[i], courseColor: colorOfCourse(i), dayColor: colorOfDay(i)))
        }
    }
    
    // MARK: - Change View

    func changeView(_ action: String, index: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let addCourseView = storyboard.instantiateViewController(withIdentifier: "addCourseView") as! addCourseVC
        
        if action == "didSelectRow" {
            addCourseView.actionFromCourseVC = action
            addCourseView.courseDetails.insert(course_id[index], at: 0)
            addCourseView.courseDetails.insert(course_name[index], at: 1)
            addCourseView.courseDetails.insert(course_lecturer[index], at: 2)
            addCourseView.courseDetails.insert(course_day[index], at: 3)
            addCourseView.courseDetails.insert(course_startTime[index], at: 4)
            addCourseView.courseDetails.insert(course_endTime[index], at: 5)
            addCourseView.courseDetails.insert(course_type[index], at: 6)
            addCourseView.courseDetails.insert(course_location[index], at: 7)
            addCourseView.courseDetails.insert(course_color[index], at: 8)
        }

        addCourseView.modalPresentationStyle = .fullScreen
        self.present(addCourseView, animated: true, completion: nil)
    }
}
