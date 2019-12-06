//
//  DetailViewController.swift
//  SuperFanSearch
//
//  Created by Frederick Cowgill on 9/3/19.
//  Copyright © 2019 Frederick Cowgill. All rights reserved.
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
        if let detailSchool = detailSchool {
            if let schoolImageView = schoolImageView, let addressTextView = addressTextView {
                schoolImageView.load(url: URL(string: detailSchool.img)!)
                title = detailSchool.name
                addressTextView.text = detailSchool.address
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

