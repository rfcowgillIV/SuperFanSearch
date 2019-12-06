//
//  SuperFanRequest.swift
//  SuperFanSearch
//
//  Created by Frederick Cowgill on 9/4/19.
//  Copyright © 2019 Frederick Cowgill. All rights reserved.
//

import Foundation

enum SchoolError:Error {
    case noDataAvailable
    case canNotProcessData
}

struct SchoolRequest {
    let searchURL:URL
    
    init(searchTerm:String) {
        let searchString = "https://api.superfanu.com/8.0/networks/container/available/search?search=\(searchTerm)"
        
        guard let searchURL = URL(string: searchString) else {fatalError()}
        
        self.searchURL = searchURL
    }
    
    func getSchools(completion: @escaping(Result<[School], SchoolError>) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: searchURL) {data, _, _ in
            guard let jsonData = data else {
                completion(.failure(.noDataAvailable))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let schoolResponse = try decoder.decode(SchoolData.self, from: jsonData)
                let schoolData = schoolResponse.data
                completion(.success(schoolData[0]))
            } catch {
                completion(.failure(.canNotProcessData))
            }
        }
        dataTask.resume()
    }
}
