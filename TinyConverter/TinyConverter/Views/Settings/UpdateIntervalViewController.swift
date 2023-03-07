//
//  UpdateIntervalTableViewController.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 13.02.20.
//  Copyright © 2020 Adnan Zildzic. All rights reserved.
//
import UIKit

class UpdateIntervalViewController: UITableViewController {
    let viewModel: UpdateIntervalViewModel

    required init?(coder: NSCoder, viewModel: UpdateIntervalViewModel) {
        self.viewModel = viewModel

        super.init(coder: coder)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.updateIntervals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "intervalCell", for: indexPath)

        let cellValue = viewModel.updateIntervals[indexPath.row]
        cell.textLabel?.text = "\(String(cellValue)) hours"

        cell.accessoryType = cellValue == viewModel.selectedInterval ? .checkmark : .none

        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let selectedRow = viewModel.updateIntervals.firstIndex(of: viewModel.selectedInterval) else { return }
        let selectedCellIndexPath = IndexPath(row: selectedRow, section: 0)

        if selectedCellIndexPath == indexPath { return }

        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        cell.accessoryType = .checkmark

        if let previouslySelectedCell = tableView.cellForRow(at: selectedCellIndexPath) {
            previouslySelectedCell.accessoryType = .none
        }

        viewModel.setUpdateInterval(viewModel.updateIntervals[indexPath.row])
    }
}
