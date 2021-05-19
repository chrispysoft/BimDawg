//
//  DepartureListController.swift
//  BimDawg
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 chrispysoft. All rights reserved.
//

import UIKit

class DepartureListController: UITableViewController {
	
	var stop: Stop?
	
	var refreshTimer: Timer?
	let refreshInterval: TimeInterval = 10
	
	
	// MARK: - ViewController methods
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		navigationItem.title = stop?.name
		
		loadDepartures()
		refreshTimer = Timer.scheduledTimer(timeInterval: refreshInterval, target: self, selector: #selector(loadDepartures), userInfo: nil, repeats: true)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		refreshTimer?.invalidate()
		refreshTimer = nil
	}
	
	
	// MARK: - Load table data
	@objc func loadDepartures() {
		NSLog("loadDepartures")
		guard let stop = stop else { NSLog("stop is nil"); return }
		let efaClient = EFAClient()
		
		efaClient.loadDepartures(for: stop.id) { [weak self] (result) in
			guard let `self` = self else { return }
			switch result {
			
			case .success(let departures):
				let sortedDepartures = departures.sorted { ($0.platform == $1.platform) ? ($0.countdown < $1.countdown) : ($0.platform < $1.platform) }
				self.tableData = TableData(with: sortedDepartures)
				
			case .failure(let error):
				self.tableData = nil
				self.handleError(error)
			}
		}
	}
    
    
    // MARK: - Error handling
    private func handleError(_ error: Error) {
        let alert = UIAlertController(title: "BimDawg Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: false)
    }
	
	
	// MARK: - TableView Data Source
	private var tableData: TableData<Departure>? { didSet {
		tableView.reloadData()
	}}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return tableData?.sections.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tableData?.sections[section].items.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let section = indexPath.section, row = indexPath.row
		let cell = tableView.dequeueReusableCell(withIdentifier: "DepartureListTableViewCellID", for: indexPath) as! DepartureListTableViewCell
		cell.departure = tableData?.sections[section].items[row]
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return tableData?.sections[section].title
	}
	
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let departureDetailController = segue.destination as? DepartureDetailController else { fatalError("Segue destination is no DepartureDetailController") }
		let indexPath = tableView.indexPathForSelectedRow!
		let section = indexPath.section
		let row = indexPath.row
		let departure = tableData?.sections[section].items[row]
		departureDetailController.departure = departure
	}
}



protocol InSectionsDivideable {
	var sectionTitle: String { get }
	func sameSection(as: Self) -> Bool
}

struct TableData<T: InSectionsDivideable> {
	struct Section<T: InSectionsDivideable> {
		var title: String
		var items: [T]
		
		init(title: String) {
			self.title = title
			self.items = []
		}
	}
	
	var sections: [Section<T>] = []
	
	init(with items: [T]) {
		var actualSection: Section<T>!
		
		for item in items {
			if actualSection == nil {
				actualSection = Section(title: item.sectionTitle)
			}
			if let last = actualSection.items.last {
				if item.sameSection(as: last) {
					actualSection.items.append(item)
				} else {
					sections.append(actualSection)
					actualSection = Section(title: item.sectionTitle)
					actualSection.items.append(item)
				}
			} else {
				actualSection.items.append(item)
			}
		}
		if let lastSection = actualSection {
			sections.append(lastSection)
		}
	}
}

extension Departure: InSectionsDivideable {
	var sectionTitle: String {
		return "Platform \(Int(platform)! + 1)"
	}
	func sameSection(as other: Departure) -> Bool {
		return self.platform == other.platform
	}
}
