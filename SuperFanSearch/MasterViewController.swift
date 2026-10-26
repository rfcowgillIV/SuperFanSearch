//
//  MasterViewController.swift
//  SuperFanSearch
//
//  Created by Frederick Cowgill on 9/3/19.
//  Copyright © 2019 Frederick Cowgill. All rights reserved.
//
//  BUG-FIX NOTES (2026)
//  - `self!` inside the network callbacks crashed the app if the screen was
//    closed before the search finished. Now uses `guard let self`.
//  - `splitViewController!` and `as!` force-unwraps were replaced with safe
//    checks, so an unexpected layout (e.g. iPad multitasking) can't crash it.
//  - Errors now show a friendly message instead of only printing to the console.
//  - Searches with only spaces are ignored, and the keyboard closes after search.
//  - Fewer exclamation points! (The code was very excited before.)
//

import UIKit

class MasterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Properties
    @IBOutlet var tableView: UITableView!

    var detailViewController: DetailViewController? = nil
    var schools = [School]()
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: - View Setup
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the Search Controller
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = "Search Schools"
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        definesPresentationContext = true

        loadSearchResults("blue")

        if let controllers = splitViewController?.viewControllers,
           let navigation = controllers.last as? UINavigationController {
            detailViewController = navigation.topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if splitViewController?.isCollapsed ?? true {
            if let selectionIndexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectionIndexPath, animated: animated)
            }
        }
        super.viewWillAppear(animated)
    }

    // MARK: - Table View
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schools.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let school = schools[indexPath.row]
        cell.textLabel?.text = school.name
        return cell
    }

    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showDetail",
              let indexPath = tableView.indexPathForSelectedRow,
              let navigation = segue.destination as? UINavigationController,
              let controller = navigation.topViewController as? DetailViewController else {
            return
        }

        controller.detailSchool = schools[indexPath.row]
        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true
    }

    func loadSearchResults(_ searchText: String) {
        let schoolRequest = SchoolRequest(searchTerm: searchText)
        schoolRequest.getSchools { [weak self] result in
            DispatchQueue.main.async {
                // If the screen was closed while we waited, just stop - no crash.
                guard let self = self else { return }

                switch result {
                case .failure(let error):
                    print("school error", error)
                    self.schools = []
                    self.tableView.reloadData()
                    self.showError("Couldn't load schools right now. Check your connection and try again.")
                case .success(let schoolData):
                    self.schools = schoolData
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func showError(_ message: String) {
        // Present from whatever is on top (the search bar may be active), and
        // don't stack a second alert on top of an existing one.
        let presenter = presentedViewController ?? self
        guard !(presenter is UIAlertController), presenter.presentedViewController == nil else { return }
        let alert = UIAlertController(title: "Search failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presenter.present(alert, animated: true)
    }
}

extension MasterViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchBarText = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchBarText.isEmpty else { return }
        searchBar.resignFirstResponder()
        loadSearchResults(searchBarText)
    }
}
