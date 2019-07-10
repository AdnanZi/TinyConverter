//
//  ViewController.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//

import UIKit

class ConverterViewController: UIViewController {
    @IBOutlet weak var baseButton: UIButton!
    @IBOutlet weak var basePicker: UIPickerView!
    @IBOutlet weak var baseAmountTextField: UITextField!

    @IBOutlet weak var targetButton: UIButton!
    @IBOutlet weak var targetPicker: UIPickerView!
    @IBOutlet weak var targetTextField: UITextField!

    let viewModel = ConverterViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        basePicker.delegate = self
        basePicker.dataSource = self
        targetPicker.delegate = self
        targetPicker.dataSource = self

        baseButton.addTarget(self, action: #selector(selectBaseCurrency), for: .touchUpInside)
        targetButton.addTarget(self, action: #selector(selectTargetCurrency), for: .touchUpInside)
    }

    @objc private func selectBaseCurrency() {
        basePicker.isHidden = false
    }

    @objc private func selectTargetCurrency() {
        targetPicker.isHidden = false
    }
}

extension ConverterViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerView.isHidden = true
        
        // set button title and set selected currency in view model
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

