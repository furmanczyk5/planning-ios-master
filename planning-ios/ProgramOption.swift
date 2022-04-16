//
//  TableOption.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 2/24/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import Foundation
import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


enum PROGRAM_FILTER {
    case none
    case upnext
    case cm(String)
    case date(Date)
    case tag(String)
    case multi_TAG([String])
}

enum ACTIVITY_DATA_SOURCE {
    case program
    case myschedule
}

struct ProgramOption {
    let title : String
    let subtitle : String?
    let description : String?
    let backgroundColor : UIColor
    let height : Int?
    
    let data_source : ACTIVITY_DATA_SOURCE
    let filter : PROGRAM_FILTER
    let max_results : Int?
    
    init(title: String, subtitle: String? = nil, description: String? = nil, backgroundColor: UIColor = UIColor.white, height: Int? = nil, data_source: ACTIVITY_DATA_SOURCE = .program, filter: PROGRAM_FILTER = .none, max_results:Int? = nil ) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.backgroundColor = backgroundColor
        self.height = height
        self.data_source = data_source
        self.filter = filter
        self.max_results = max_results
    }
    
    var filter_closure : (Activity) -> Bool {
        get {
            var return_closure : (Activity) -> Bool
            
            switch filter {
            case .none:
                return_closure = { (activity: Activity) -> Bool in return true }
            case .upnext:
                return_closure = {
                    (activity: Activity) -> Bool in
                    let begin_time = activity.begin_time
                    let calendar = Calendar.current
                    var comps = DateComponents()
                    comps.minute = -15
                    let date_cutoff = (calendar as NSCalendar).date(byAdding: comps, to: Date(), options: NSCalendar.Options()) //15 minutes ago
                    
                    if begin_time == nil{
                       return false
                    }
                    else if begin_time?.compare(date_cutoff!) == ComparisonResult.orderedDescending
                    {
                        return true // after_cutoff
                    } else if begin_time?.compare(date_cutoff!) == ComparisonResult.orderedAscending
                    {
                        return false // before cutoff
                    } else // exactly the cutoff, shouldn't really happen, but who knows
                    {
                        return true
                    }
                }
            case .cm(let cm_filter):
            
                if cm_filter == "LAW" {
                    return_closure = {(activity:Activity) -> Bool in
                        let value_double = activity.cm_law as? Double
                        return value_double != nil && value_double > 0.0
                    }
                }else if cm_filter == "ETHICS" {
                    return_closure = {(activity:Activity) -> Bool in
                        let value_double = activity.cm_ethics as? Double
                        return value_double != nil && value_double > 0.0
                    }
                }else{
                    return_closure = {(activity:Activity) -> Bool in
                        let value_double = activity.cm as? Double
                        return value_double != nil && value_double > 0.0
                    }
                }
                
            case .date(let filter_date):
                return_closure = { (activity: Activity) -> Bool in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    dateFormatter.timeZone = TimeZone(identifier:appCore.timeZoneName)
                    if let begin_time = activity.begin_time {
                        return dateFormatter.string(from: begin_time as Date) == dateFormatter.string(from: filter_date)
                    }else{
                        return false
                    }
                }
            case .tag(let tag_name):
                return_closure = {(activity: Activity) -> Bool in
                    return ",\(activity.tags),".range(of: ",\(tag_name),") != nil
                }
            case .multi_TAG(let tag_array):
                return_closure = {(activity: Activity) -> Bool in
                    for tag in tag_array {
                        if ",\(activity.tags),".range(of: ",\(tag),") != nil {
                            return true
                        }
                    }
                    return false
                }
            default:
                return_closure = {(activity: Activity) -> Bool in return false }
            }
            
            return return_closure
        }
    }
    
    static func upNextFilter(_ activity_list:[Activity]) -> [Activity] {
        var result_count = 0
        let calendar = Calendar.current
        var comps = DateComponents()
        comps.minute = -30
        var last_begin_time = (calendar as NSCalendar).date(byAdding: comps, to: Date(), options: NSCalendar.Options())
        
        var activities_filtered : [Activity] = []
        
        for activity in activity_list {
            
            let is_past = activity.begin_time?.compare(Date()) == ComparisonResult.orderedAscending
            let comparison = activity.begin_time?.compare(last_begin_time!)
            
            if activity.begin_time != nil  && comparison != ComparisonResult.orderedAscending && (result_count < 10 || comparison != ComparisonResult.orderedDescending || is_past) {
                activities_filtered.append(activity)
                result_count += 1
                last_begin_time = activity.begin_time! as Date
            }else if result_count > 10{
                break
            }
            
        }
        return activities_filtered
    }
 }

let PROGRAM_TABLE_OPTIONS = [
    (section: "", options: [
        ProgramOption(title: "My Schedule",
                      description:"",
                      data_source: .myschedule),
        ProgramOption(title: "Full Program", description:"")
        ]),
    (section: "Activity Type", options: [
        ProgramOption(title: "Sessions & Discussions",
                      description: "",
                      filter: .tag("Sessions & Discussions")),
        ProgramOption(title: "Mobile Workshops & Orientation Tours",
                      description: "",
                      filter: .tag("Mobile Workshops & Orientation Tours")),
        ProgramOption(title: "Advanced Workshops & Institutes",
                      description: "",
                      filter: .tag("Advanced Workshops & Institutes")),
        ProgramOption(title: "Posters",
                      description: "",
                      filter: .tag("Posters") ),
        ProgramOption(title: "Ticketed Special Events",
                      description: "",
                      filter: .tag("Ticketed Special Events")),
        ProgramOption(title: "Meetings",
                      description: "",
                      filter: .tag("Meetings")),
        ProgramOption(title: "Networking Receptions",
                      description: "",
                      filter: .tag("Networking Receptions"))
        ]),
    (section: "CM Filter", options: [
        ProgramOption(title: "All CM",
                      description: "",
                      filter: .cm("CM") ),
        ProgramOption(title: "CM Law",
                      description: "",
                      filter: .cm("LAW") ),
        ProgramOption(title: "CM Ethics",
                      description: "",
                      filter: .cm("ETHICS") )
        ]),
    (section: "Program By Day", options: [
        ProgramOption(title: "Saturday, May 6",
                      description: "",
                      filter: .date(Date(dateString: "2017-05-06", timezone:appCore.timeZoneName)) ),
        ProgramOption(title: "Sunday, May 7",
                      description: "",
                      filter: .date(Date(dateString: "2017-05-07",timezone:appCore.timeZoneName)) ),
        ProgramOption(title: "Monday, May 8",
                      description: "",
                      filter: .date(Date(dateString: "2017-05-08", timezone:appCore.timeZoneName)) ),
        ProgramOption(title: "Tuesday, May 9",
                      description: "",
                      filter: .date(Date(dateString: "2017-05-09", timezone:appCore.timeZoneName)) )
        ]),
    (section: "Audience", options: [
        ProgramOption(title: "Masters Series",
                      description: "",
                      filter: .tag("Master Series")),
        ProgramOption(title: "Emerging Professionals",
                      description: "",
                      filter: .tag("Emerging Professionals")),
        ProgramOption(title: "Planning Commissioners & Officials",
                      description: "",
                      filter: .tag("Planning Commissioners & Officials")),
        ]),
    (section: "Divisions", options: [
        ProgramOption(title: "City Planning and Management",
                      description: "",
                      filter: .tag("City Planning and Management Division")),
        ProgramOption(title: "County Planning",
                      description: "",
                      filter: .tag("County Planning Division")),
        ProgramOption(title: "Economic Development",
                      description: "",
                      filter: .tag("Economic Development Division")),
        ProgramOption(title: "Environment, Natural Resources, and Energy",
                      description: "",
                      filter: .tag("Environment, Natural Resources, and Energy Division")),
        ProgramOption(title: "Federal Planning",
                      description: "",
                      filter: .tag("Federal Planning Division")),
        ProgramOption(title: "Hazard Mitigation and Disaster Recovery Planning",
                      description: "",
                      filter: .tag("Hazard Mitigation and Disaster Recovery Planning Division")),
        ProgramOption(title: "Housing and Community Development",
                      description: "",
                      filter: .tag("Housing and Community Development Division")),
        ProgramOption(title: "International",
                      description: "",
                      filter: .tag("International Division")),
        ProgramOption(title: "Latinos and Planning",
                      description: "",
                      filter: .tag("Latinos and Planning Division")),
        ProgramOption(title: "LGBTQ and Planning",
                      description: "",
                      filter: .tag("LGBTQ and Planning Division")),
        ProgramOption(title: "New Urbanism",
                      description: "",
                      filter: .tag("New Urbanism Division")),
        ProgramOption(title: "Planning and Law",
                      description: "",
                      filter: .tag("Planning and Law Division")),
        ProgramOption(title: "Planning and the Black Community",
                      description: "",
                      filter: .tag("Planning and the Black Community Division")),
        ProgramOption(title: "Private Practice",
                      description: "",
                      filter: .tag("Private Practice Division")),
        ProgramOption(title: "Regional and Intergovernmental Planning",
                      description: "",
                      filter: .tag("Regional and Intergovernmental Planning Division")),
        ProgramOption(title: "Small Town and Rural Planning",
                      description: "",
                      filter: .tag("Small Town and Rural Planning Division")),
        ProgramOption(title: "Sustainable Communities",
                      description: "",
                      filter: .tag("Sustainable Communities Division")),
        ProgramOption(title: "Technology",
                      description: "",
                      filter: .tag("Technology Division")),
        ProgramOption(title: "Transportation",
                      description: "",
                      filter: .tag("Transportation Planning Division")),
        ProgramOption(title: "Urban Design and Preservation",
                      description: "",
                      filter: .tag("Urban Design and Preservation Division")),
        ProgramOption(title: "Women and Planning",
                      description: "",
                      filter: .tag("Women and Planning Division"))
    ]),
    (section: "Tracks", options: [
        ProgramOption(title: "From Climate Change to Resilience",
                      description: "Several themes will be pursued in this track. First: Sea-level rise and coastal cities and infrastructure. The enormity of the issue will be examined in terms of the vulnerability of major coastal cities. Second: Extreme weather and changing weather cycles that require planners and their communities to be prepared to deal with hazards. Third: How resilience can mean not only withstanding natural hazards but also adapting to economic and other changes — whether sudden or gradual. Managing and planning for water will be addressed throughout.",
                      filter: .tag("From Climate Change to Resilience")),
        ProgramOption(title: "Contemporary Design Skills in an Interdisciplinary Work Place",
                      description: "New technology tools have made urban design concepts accessible to the public and strengthened planners' role in design. Design is also an interdisciplinary undertaking and presentations examine how planning contributes and functions within this context. What skills do you need to get on the team and how do you need to function once you are on the team? This topic also may address collective impact and cross-sector partnerships. Sessions will help prepare planners for workforce changes.",
                      filter: .tag("Contemporary Design Skills in an Interdisciplinary Work Place")),
        ProgramOption(title: "Disruptive Economic Development",
                      description: "Disruption comes in many forms, from the evolving \"sharing economy,\" to technological inventions like mobile apps and fracking, to new lifestyle choices. This track explores everything from new locales for winemaking, hip and attractive small towns, casinos, and increased personal choices enabled by technological inventions. These rapidly evolving phenomena are inventing new opportunities and creating new challenges for communities. What's next? How are communities responding constructively? How does rapid change work with planning?",
                      filter: .tag("Disruptive Economic Development")),
        ProgramOption(title: "Housing and Inequality",
                      description: "There is an urgent need to address long-standing inequity and place decent housing at the center of the planning and policy agenda. Income and opportunity gaps keep widening. Is this inevitable or can responsible government, civic vision, and commitment to fairness make a significant difference? Sessions will explore the issues, assess the responses, and examine effective approaches. Topics also may include income disparity, location and poverty, and gentrification.",
                      filter: .tag("Housing and Inequality")),
        ProgramOption(title: "Leadership in Planning",
                      description: "Planners lead the public discussion of future development. But how else can they lead in their communities and promote their profession? Leadership is about where you focus attention and which problems you choose to solve. Leadership is about opening horizons for consideration and opportunity. Leadership is about creating results. Sessions in this track delve into leadership and provide training and guidance on how planning can help create agendas, advocate for just development, and stand for quality decision making. Reassess how to develop as a leader and how to develop others to lead in planning and creating great communities.",
                      filter: .tag("Leadership in Planning")),
        ProgramOption(title: "Fiscal Analysis, Municipal Finance, and the Economy",
                      description: "The 2008-09 Great Recession restructured much of the economy and laid bare the fragile condition of local government budgets. Sessions will delve into how cities have rethought their financial base and are retololing to provide basic goods and services, plan for the future, and escape a cycle of recurring crises. Some sessions may examine how private development intersects with government. Others may look at how communities are using new tools or rethinking existing ones, and pursuing fiscal health and new forms of economic development. Every planner needs to know about this vital subject. How does the physical environment of our communities contribute to and benefit from economic and fiscal health. Sponsoring Partner: Lincoln Institute of Land Policy",
                      filter: .tag("Fiscal Analysis, Municipal Finance, and the Economy")),
        ProgramOption(title: "Metrics, Public Response, and Indicators to Track Success",
                      description: "Accountability, personal control, and flexible decision making are all touted as hallmarks of good planning and planning management. Planners feel the pressure to demonstrate the effectiveness and value of planning. Sessions explore the measures by which planners, officials, and the public measure planning success. Which ones work best and what do community members actually learn? Does more data make for greater accountability? How can public interest be harnessed in the quest for measureable results?",
                      filter: .tag("Metrics, Public Response, and Indicators to Track Success")),
        ProgramOption(title: "New Horizons in Parks and Planning",
                      description: "In New York City, one of the nation's greatest centers of park planning, the National Planning Conference will consider the innovations, impacts, and creative rethinking that are shaping our cities through parks. Emerging from a period of disinvestment, parks have moved to the center of many contemporary conversations about health, hazard mitigation, economic development, urban design, environmental restoration, and must-have amenities in both small towns and larger cities. Sessions will consider both private and public spaces and will highlight widespread innovation.",
                      filter: .tag("New Horizons in Parks and Planning")),
        ProgramOption(title: "Planning Law",
                      description: "How have the courts shaped planning and land use law? Have new trends emerged at the state level? Explore the big picture and the specific impact of planning law in these sessions.",
                      filter: .tag("Planning Law")),
        ProgramOption(title: "Redevelopment Makes an Impact",
                      description: "Various themes of redevelopment will be explored. First: Art and culture. These have become major draws for tourists in large cities and small towns. Sessions also may explore how they have become a necessary amenity for communities seeking to grow or stabilize their population. Second: The connection between inner-city rebirth and suburban distress. As urban downtowns revive in many parts of the country, inner-ring and older suburbs experience new problems that include social service demands, aging infrastructure, and shifting populations and tax bases. Sessions could explore how to sustain a tax base and how regions must plan to thrive. Third: Communities that have revived their centers and redeveloped their corridors to adapt to new patterns and attract new uses.",
                      filter: .tag("Redevelopment Makes an Impact")),
        ProgramOption(title: "Transportation: From Mega-Projects to Personal Commuting Decisions",
                      description: "The world of transportation is changing rapidly. The skills needed to keep abreast are critical. Some sessions in this track will consider the largest transportation planning projects and how they are planned and executed. Technology and personal choices also are affecting transportation planning. What do we know about the impact of these developments and how should a 21st-century transportation planner adapt? Sessions may also address issues of street design.",
                      filter: .tag("Transportation: From Mega-Projects to Personal Commuting Decisions")),
        ProgramOption(title: "Zoning: Hitting the Reset Button",
                      description: "Recent decades have witnessed the rise of entirely new approaches to a core tool of planning. Zoning is addressing issues that once were considered outside its domain — equity, the environment, and even three-dimensional urban design. With these changes has come the need for planners who are equipped with the knowledge and skills to implement increasingly sophisticated regulations, incentives, and tools. Sessions will explore how zoning that is more responsive and carefully calibrated than ever is changing the face and function of communities.",
                      filter: .tag("Zoning: Hitting the Reset Button"))
        
        //ProgramOption(title: "Evolving Solar, Wind, and Energy Planning",           filter: .tag("Evolving Solar, Wind, and Energy Planning")),
        //ProgramOption(title: "Housing Trends",                                      filter: .tag("Housing Trends")),
        //ProgramOption(title: "Lessons from the Recession",                          filter: .tag("Lessons from the Recession")),
        //ProgramOption(title: "Nuts and Bolts",                                      filter: .tag("Nuts and Bolts")),
        //ProgramOption(title: "Planning and the Regulatory Realm",                   filter: .tag("Planning and the Regulatory Realm")),
        //ProgramOption(title: "Planning for a More Dynamic Population",              filter: .tag("Planning for a More Dynamic Population")),
        //ProgramOption(title: "Planning for All Generations",                        filter: .tag("Planning for All Generations")),
        //ProgramOption(title: "Public Health and Planning for Resilience",           filter: .tag("Public Health and Planning for Resilience")),
        //ProgramOption(title: "Real Estate and Finance and Role of Planning",        filter: .tag("Real Estate and Finance and Role of Planning")),
        //ProgramOption(title: "Water and Community Planning",                        filter: .tag("Water and Community Planning")),
        //ProgramOption(title: "Local Host Committee",                                filter: .tag("Local Host Committee")),
        ])
]
