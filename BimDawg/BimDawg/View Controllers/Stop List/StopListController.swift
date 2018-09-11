//
//  StopListController.swift
//  BimDawg
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 chrispysoft. All rights reserved.
//

import UIKit
import CoreLocation

class StopListController: UITableViewController {
	
	private let coordinateProvider = CoordinateProvider()
	private let stopListModel = StopListModel()
	
	
	override func viewDidLoad() {
		definesPresentationContext = true
		coordinateProvider.updateHandler = { result in
			switch result {
			case .success(let location):
				self.stopListModel.currentLocation = location
			case .failure(let error):
				self.handleError(error)
			}
		}
		stopListModel.updateHandler = stopListChangedHandler
	}
	
	override func viewDidAppear(_ animated: Bool) {
		stopListModel.paused = false
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		stopListModel.paused = true
	}
	
	
	private func coordinateChangedHandler(_ location: CLLocation) {
		stopListModel.currentLocation = location
	}
	
	
	private func stopListChangedHandler(result: StopListModel.UpdateResult) {
		print("stopList changed")
		
		switch result {
		case .success:
			tableView.reloadData()
		case .failure(let error):
			handleError(error)
		}
	}
	
	// MARK: - Error handling
	private func handleError(_ error: Error) {
        let alert = UIAlertController(title: "BimDawg Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: false)
	}
	
	
	// MARK: - TableView Data Source
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return stopListModel.numberOfStops
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "StopListTableViewCellID", for: indexPath) as! StopListTableViewCell
		cell.stopListModel = self.stopListModel
		let stop = stopListModel.stop(at: indexPath.row)
		cell.stop = stop
		return cell
	}
	
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let departureListController = segue.destination as? DepartureListController {
			guard let row = tableView.indexPathForSelectedRow?.row else { return }
			guard let stop = stopListModel.stop(at: row) else { return }
			departureListController.stop = stop
		}
	}
}
