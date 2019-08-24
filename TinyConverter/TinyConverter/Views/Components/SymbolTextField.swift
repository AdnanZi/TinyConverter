//
//  SymbolTextField.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 19.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//

import UIKit

class SymbolTextField: UITextField {
    let symbolPickerView = UIPickerView()
    private var doneButton: UIBarButtonItem!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        inputView = symbolPickerView // bug: preselected symbol isn't preselected in picker

        let flexButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(closePicker))

        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: frame.width, height: 44))
        toolbar.items = [flexButton, doneButton]

        inputAccessoryView = toolbar
    }

    @objc private func closePicker() {
        resignFirstResponder()
    }
}
