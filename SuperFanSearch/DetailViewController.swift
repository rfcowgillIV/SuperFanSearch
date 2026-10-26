//
//  DetailViewController.swift
//  SuperFanSearch
//
//  Created by Frederick Cowgill on 9/3/19.
//  Copyright © 2019 Frederick Cowgill. All rights reserved.
//
//  SECURITY + BUG-FIX NOTES (2026)
//  - `URL(string: detailSchool.img)!` crashed the app whenever the API sent a
//    missing or malformed image link. It now skips the image safely.
//  - Images are downloaded with URLSession instead of `Data(contentsOf:)`.
//    Data(contentsOf:) is meant for local files; on a network URL it blocks a
//    thread with no timeout and Apple's docs warn against it.
//  - Plain "http://" image links are upgraded to "https://", because the app no
//    longer allows insecure connections (see Info.plist notes).
//  - If you tap a second school before the first image finishes, the old image
//    can no longer pop in on top of the new one.
//  - Only images under 10 MB are accepted, so a huge file can't eat memory.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var schoolImageView: UIImageView!

    @IBOutlet weak var addressTextView: UITextView!

    var detailSchool: School? {
        didSet {
            configureView()
        }
    }

    func configureView() {
        guard let detailSchool = detailSchool,
              let schoolImageView = schoolImageView,
              let addressTextView = addressTextView else {
            return
        }

        title = detailSchool.name
        addressTextView.text = detailSchool.address
        schoolImageView.image = nil
        if let imageURL = URL.secureImageURL(from: detailSchool.img) {
            schoolImageView.load(url: imageURL)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
}

extension URL {
    /// Builds an https URL from the API's image string, or nil if it's unusable.
    static func secureImageURL(from string: String) -> URL? {
        guard var components = URLComponents(string: string.trimmingCharacters(in: .whitespaces)) else { return nil }
        if components.scheme?.lowercased() == "http" {
            components.scheme = "https"
        }
        guard components.scheme?.lowercased() == "https", components.host != nil else { return nil }
        return components.url
    }
}

private var currentImageURLKey: UInt8 = 0

extension UIImageView {
    /// The URL this image view is currently waiting on (used to ignore stale downloads).
    private var currentImageURL: URL? {
        get { objc_getAssociatedObject(self, &currentImageURLKey) as? URL }
        set { objc_setAssociatedObject(self, &currentImageURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func load(url: URL) {
        currentImageURL = url
        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let data = data,
                  data.count < 10_000_000,
                  (response as? HTTPURLResponse)?.statusCode ?? 200 < 400,
                  let image = UIImage(data: data) else {
                return
            }
            DispatchQueue.main.async {
                // Only show it if this is still the image we want. Picture perfect.
                guard let self = self, self.currentImageURL == url else { return }
                self.image = image
            }
        }.resume()
    }
}
