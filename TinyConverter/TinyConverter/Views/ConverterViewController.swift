//
//  ConverterViewController.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import UIKit

@objc protocol ConverterViewControllerDelegate: AnyObject {
    func navigateToSettings()
}

class ConverterViewController: UIViewController {
    let baseSymbolTextField = SymbolTextField()
    let baseAmountTextField = UITextField()

    let targetSymbolTextField = SymbolTextField()
    var targetAmountTextField = UITextField()

    let spinner = UIActivityIndicatorView()

    let lastUpdateDateLabel = UILabel()

    weak var delegate: ConverterViewControllerDelegate!

    let viewModel: ConverterViewModel
    var observations = [NSKeyValueObservation]()

    init(viewModel: ConverterViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupObservables()

        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        let baseStackView = UIStackView()
        baseStackView.axis = .vertical
        baseStackView.spacing = 16
        baseStackView.translatesAutoresizingMaskIntoConstraints = false

        let baseCurrencyLabel = UILabel()
        baseCurrencyLabel.text = "Base Currency"
        baseStackView.addArrangedSubview(baseCurrencyLabel)

        baseSymbolTextField.textColor = .systemBlue
        baseStackView.addArrangedSubview(baseSymbolTextField)

        baseAmountTextField.placeholder = "Amount"
        baseAmountTextField.keyboardType = .numbersAndPunctuation
        baseAmountTextField.borderStyle = .roundedRect
        baseAmountTextField.font = .systemFont(ofSize: 20)
        baseStackView.addArrangedSubview(baseAmountTextField)

        let targetStackView = UIStackView()
        targetStackView.axis = .vertical
        targetStackView.spacing = 16
        targetStackView.translatesAutoresizingMaskIntoConstraints = false

        let targetCurrencyLabel = UILabel()
        targetCurrencyLabel.text = "Target Currency"
        targetStackView.addArrangedSubview(targetCurrencyLabel)

        targetSymbolTextField.textColor = .systemBlue
        targetStackView.addArrangedSubview(targetSymbolTextField)

        targetAmountTextField.placeholder = "Amount"
        targetAmountTextField.keyboardType = .numbersAndPunctuation
        targetAmountTextField.borderStyle = .roundedRect
        targetAmountTextField.font = .systemFont(ofSize: 20)
        targetStackView.addArrangedSubview(targetAmountTextField)

        let updateDateStackView = UIStackView()
        updateDateStackView.translatesAutoresizingMaskIntoConstraints = false

        let updateDateTitleLabel = UILabel()
        updateDateTitleLabel.text = "Last Update: "
        updateDateStackView.addArrangedSubview(updateDateTitleLabel)
        updateDateStackView.addArrangedSubview(lastUpdateDateLabel)

        spinner.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(baseStackView)
        view.addSubview(targetStackView)
        view.addSubview(updateDateStackView)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: baseStackView.trailingAnchor, constant: 16),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: targetStackView.trailingAnchor, constant: 16),
            baseStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            baseStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            baseStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            targetStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            targetStackView.topAnchor.constraint(equalTo: baseStackView.bottomAnchor, constant: 32),
            updateDateStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            updateDateStackView.topAnchor.constraint(equalTo: targetStackView.bottomAnchor, constant: 70),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

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
        observations = [
            viewModel.bind(\.baseCurrency, to: baseSymbolTextField, at: \.text),
            viewModel.bind(\.targetCurrency, to: targetSymbolTextField, at: \.text),
            viewModel.bind(\.showSpinner, to: spinner, at: \.animating),
            viewModel.bind(\.baseAmount, to: baseAmountTextField, at: \.text),
            viewModel.bind(\.targetAmount, to: targetAmountTextField, at: \.text),
            viewModel.bind(\.latestUpdateDate, to: lastUpdateDateLabel, at: \.text),
            viewModel.observe(\.alert, options: [.new]) { [weak self] _, change in self?.showAlert(change.newValue!) }
        ]
    }

    private func showAlert(_ alertOptions: Alert?) {
        guard let alertOptions else {
            return
        }

        let alert = UIAlertController(title: alertOptions.alertTitle, message: alertOptions.alertText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in self?.viewModel.fetchData() }))

        present(alert, animated: true, completion: nil)
    }

    @objc private func appDidBecomeActive() {
        fetchData()
    }

    private func fetchData() {
        viewModel.fetchData()
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
