//
//  ConverterViewController.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import UIKit
import Combine

@objc protocol ConverterViewControllerDelegate: class {
    func navigateToSettings()
}

class ConverterViewController: UIViewController {
    @IBOutlet weak var baseSymbolTextField: SymbolTextField!
    @IBOutlet weak var baseAmountTextField: UITextField!

    @IBOutlet weak var targetSymbolTextField: SymbolTextField!
    @IBOutlet weak var targetAmountTextField: UITextField!

    @IBOutlet weak var spinner: UIActivityIndicatorView!

    @IBOutlet weak var lastUpdateDateLabel: UILabel!

    weak var delegate: ConverterViewControllerDelegate!

    var viewModel: ConverterViewModel!

    private var cancellable = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupObservables()

        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchData()
    }

    private func setupViews() {
        let basePicker = baseSymbolTextField.symbolPickerView!
        basePicker.dataSource = self
        basePicker.delegate = self

        let targetPicker = targetSymbolTextField.symbolPickerView!
        targetPicker.dataSource = self
        targetPicker.delegate = self

        baseAmountTextField.delegate = self
        targetAmountTextField.delegate = self
    }

    private func setupObservables() {
        viewModel.$baseCurrency
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: baseSymbolTextField)
            .store(in: &cancellable)

        viewModel.$targetCurrency
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: targetSymbolTextField)
            .store(in: &cancellable)

        viewModel.$baseAmount
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: baseAmountTextField)
            .store(in: &cancellable)

        viewModel.$targetAmount
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: targetAmountTextField)
            .store(in: &cancellable)

        viewModel.$latestUpdateDate
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: lastUpdateDateLabel)
            .store(in: &cancellable)

        viewModel.spinnerPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                $0 ? self?.spinner.startAnimating() : self?.spinner.stopAnimating()
            }
            .store(in: &cancellable)

        viewModel.alertPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.showAlert($0)
            }
            .store(in: &cancellable)
    }

    private func showAlert(_ alertOptions: Alert?) {
        guard let alertOptions = alertOptions else {
            return
        }

        let alert = UIAlertController(title: alertOptions.alertTitle, message: alertOptions.alertText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in self?.fetchData() }))

        present(alert, animated: true, completion: nil)
    }

    @objc private func appDidBecomeActive() {
        fetchData()
    }

    private func fetchData() {
        viewModel.fetchData().ignoreOutput()
    }
}

extension ConverterViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let value = viewModel.exchangeRates[row].code

        if pickerView == baseSymbolTextField.symbolPickerView {
            viewModel.baseCurrency = value
        } else {
            viewModel.targetCurrency = value
        }
    }
}

extension ConverterViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.exchangeRates.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewModel.exchangeRates[row].name
    }
}

extension ConverterViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var allowedCharacters = CharacterSet.decimalDigits
        allowedCharacters.insert(".")
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        guard let text = textField.text else {
            return true
        }

        if textField == baseAmountTextField {
            viewModel.baseAmount = text
        } else {
            viewModel.targetAmount = text
        }

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
