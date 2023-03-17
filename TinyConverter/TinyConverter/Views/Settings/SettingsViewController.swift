//
//  SettingsTableViewController.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 13.02.20.
//  Copyright © 2020 Adnan Zildzic. All rights reserved.
//
import UIKit
import Combine

protocol SettingsViewControllerDelegate: AnyObject {
    func selectUpdateInterval()
}

class SettingsViewController: UITableViewController {
    var updateOnStartSwitch = UISwitch()
    var autoUpdatesSwitch = UISwitch()
    var updateIntervalCell: UITableViewCell? {
        tableView.cellForRow(at: IndexPath(row: 2, section: 0))
    }

    weak var delegate: SettingsViewControllerDelegate!

    let viewModel: SettingsViewModel

    private var cancellable = Set<AnyCancellable>()

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.$updateOnStart
            .receive(on: RunLoop.main)
            .assign(to: \.isOn, on: updateOnStartSwitch)
            .store(in: &cancellable)

        viewModel.$automaticUpdates
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                self.autoUpdatesSwitch.isOn = $0
                self.updateIntervalCell?.accessoryType = self.autoUpdatesSwitch.isOn ? .disclosureIndicator : .none
            }
            .store(in: &cancellable)

        viewModel.$updateInterval
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.updateIntervalCell?.detailTextLabel?.text = $0
            }
            .store(in: &cancellable)

        viewModel.$automaticUpdates
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, let cell = self.updateIntervalCell else { return }

                cell.isUserInteractionEnabled = self.autoUpdatesSwitch.isOn
                cell.accessoryType = self.autoUpdatesSwitch.isOn ? .disclosureIndicator : .none
            }
            .store(in: &cancellable)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.refreshUpdateInterval()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let identifier = "updateOnStart"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .value1, reuseIdentifier: identifier)

            cell.textLabel?.text = "Update On Start"
            cell.accessoryView = updateOnStartSwitch

            updateOnStartSwitch.addTarget(self, action: #selector(updateOnStartToggled), for: .valueChanged)

            return cell
        case 1:
            let identifier = "autoUpdates"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .value1, reuseIdentifier: identifier)

            cell.textLabel?.text = "Automatic Updates"
            cell.accessoryView = autoUpdatesSwitch

            autoUpdatesSwitch.addTarget(self, action: #selector(autoUpdatesToggled), for: .valueChanged)

            return cell
        case 2:
            let identifier = "updateInterval"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .value1, reuseIdentifier: identifier)

            cell.textLabel?.text = "Update Interval"
            cell.accessoryType = self.autoUpdatesSwitch.isOn ? .disclosureIndicator : .none

            return cell
        default:
            fatalError("No such cell exists.")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 2 {
            delegate.selectUpdateInterval()
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }

    @objc func updateOnStartToggled(_ sender: UISwitch) {
        viewModel.updateOnStartSubject.send(sender.isOn)
    }

    @objc func autoUpdatesToggled(_ sender: UISwitch) {
        viewModel.automaticUpdatesSubject.send(sender.isOn)
    }
}
