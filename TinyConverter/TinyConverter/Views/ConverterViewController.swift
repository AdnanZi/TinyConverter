//
//  ConverterViewController.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//

import UIKit

class ConverterViewController: UIViewController {
    @IBOutlet weak var baseSymbolTextField: UITextField!
    @IBOutlet weak var baseAmountTextField: UITextField!

    @IBOutlet weak var targetSymbolTextField: UITextField!
    @IBOutlet weak var targetAmountTextField: UITextField!

    @IBOutlet weak var spinner: UIActivityIndicatorView!

    let basePicker = UIPickerView()
    let targetPicker = UIPickerView()

    let viewModel = ConverterViewModel()
    var observations = [NSKeyValueObservation]()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupObservables()

        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func setupViews() {
        basePicker.dataSource = self
        basePicker.delegate = self
        targetPicker.dataSource = self
        targetPicker.delegate = self

        baseSymbolTextField.inputView = basePicker
        targetSymbolTextField.inputView = targetPicker

        baseAmountTextField.delegate = self
        targetAmountTextField.delegate = self
    }

    @objc private func selectBaseCurrency() {
        basePicker.isHidden = false
    }

    @objc private func selectTargetCurrency() {
        targetPicker.isHidden = false
    }

    private func setupObservables() {
        observations = [
            viewModel.bind(\.baseCurrency, to: baseSymbolTextField, at: \.text),
            viewModel.bind(\.targetCurrency, to: targetSymbolTextField, at: \.text),
            viewModel.bind(\.showSpinner, to: spinner, at: \.animating),
            viewModel.bind(\.baseAmount, to: baseAmountTextField, at: \.text),
            viewModel.bind(\.targetAmount, to: targetAmountTextField, at: \.text),
            viewModel.observe(\.alert, options: [.new]) { [weak self] _, change in self?.showAlert(change.newValue!) }
        ]
    }

    private func showAlert(_ alertOptions: Alert?) {
        guard let alertOptions = alertOptions else {
            return
        }

        let alert = UIAlertController(title: alertOptions.alertTitle, message: alertOptions.alertText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in self?.viewModel.fetchData() }))

        present(alert, animated: true, completion: nil)
    }

    @objc private func appDidBecomeActive() {
        viewModel.fetchData()
    }
}

extension ConverterViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let value = viewModel.symbols[row]

        if pickerView == basePicker {
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
        return viewModel.symbols.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewModel.symbols[row]
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
            viewModel.baseAmountEntered = text
        } else {
            viewModel.targetAmountEntered = text
        }

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
