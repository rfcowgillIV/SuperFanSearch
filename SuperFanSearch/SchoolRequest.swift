//
//  SuperFanRequest.swift
//  SuperFanSearch
//
//  Created by Frederick Cowgill on 9/4/19.
//  Copyright © 2019 Frederick Cowgill. All rights reserved.
//
//  ===========================================================================
//  SECURITY + BUG-FIX NOTES (2026)
//  ===========================================================================
//  1. The search text is now URL-encoded with URLComponents. Before, it was
//     pasted straight into the URL string:
//       - Typing a space, "&", or "#" made URL(string:) return nil, which hit
//         `fatalError()` and CRASHED the app. (Try searching "St. Mary's".)
//       - Typing "&other=value" could add extra parameters to the API call
//         (query injection).
//  2. Network errors and non-200 HTTP responses are reported instead of being
//     ignored.
//  3. `schoolData[0]` crashed when the API returned an empty list. It now
//     returns an empty array safely.
//  4. Requests time out after 15 seconds instead of hanging forever.
//
//  Request accepted. Response: school's in session.
//  ===========================================================================

import Foundation

enum SchoolError: Error {
    case noDataAvailable
    case canNotProcessData
    case invalidSearch
    case badResponse(statusCode: Int)
}

struct SchoolRequest {
    let searchURL: URL?

    init(searchTerm: String) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.superfanu.com"
        components.path = "/8.0/networks/container/available/search"
        // URLComponents percent-encodes the value, so any characters are safe.
        components.queryItems = [URLQueryItem(name: "search", value: searchTerm)]
        self.searchURL = components.url
    }

    func getSchools(completion: @escaping (Result<[School], SchoolError>) -> Void) {
        guard let searchURL = searchURL else {
            completion(.failure(.invalidSearch))
            return
        }

        var request = URLRequest(url: searchURL)
        request.timeoutInterval = 15

        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(.failure(.noDataAvailable))
                return
            }

            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                completion(.failure(.badResponse(statusCode: http.statusCode)))
                return
            }

            guard let jsonData = data else {
                completion(.failure(.noDataAvailable))
                return
            }

            do {
                let decoder = JSONDecoder()
                let schoolResponse = try decoder.decode(SchoolData.self, from: jsonData)
                // BUG FIX: `.first ?? []` instead of `[0]`, which crashed on an empty result.
                completion(.success(schoolResponse.data.first ?? []))
            } catch {
                completion(.failure(.canNotProcessData))
            }
        }
        dataTask.resume()
    }
}
