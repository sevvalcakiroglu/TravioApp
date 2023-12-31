//
//  ChangePasswordCell.swift
//  TravioApp
//
//  Created by Şevval Çakıroğlu on 5.09.2023.
//

import Foundation
import UIKit
import SnapKit



class ChangePasswordCell: UITableViewCell {
    
    var delegate: ChangePasswordDelegate?
    
    var passConfirm: (tag:Int,text:String)?
    
    private lazy var passwordView: CustomTextField = {
        let pw = CustomTextField()
        pw.labelText = ""
        pw.txtField.isSecureTextEntry = true
        pw.txtField.placeholder = ""
        pw.txtField.delegate = self
        return pw
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupView(){
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubviews(passwordView)
        setupLayout()
    }
    
    func setupLayout(){
        passwordView.snp.makeConstraints({make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.bottom.equalToSuperview().offset(-4)
        })
        
    }
    func configure(data: ChangePassword){
        
        
        passwordView.labelText = data.labelName
        passwordView.txtField.tag = data.tag
        
    }
    

    
}


extension ChangePasswordCell: UITextFieldDelegate{
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == passwordView.txtField {
            if let text = textField.text {
                tag = textField.tag
                passConfirm = (tag: tag, text: text)
                delegate?.passwordTransfer(newPassword: passConfirm!)
            }
        }
    }
    
}

