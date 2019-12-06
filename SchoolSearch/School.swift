//
//  File.swift
//  SuperFanSearch
//
//  Created by Frederick Cowgill on 9/4/19.
//  Copyright © 2019 Frederick Cowgill. All rights reserved.
//

import Foundation

//Starting here we build the array from the API from in inside out
//So Tech the data is starting from the inner most point at the bottom
//And at the top the data should be the very last point in the Array itself

struct SchoolData: Codable {
    var data: [[School]]
}

struct School: Codable {
    let nid: String
    let name : String
    let address : String
    let img: String
}
