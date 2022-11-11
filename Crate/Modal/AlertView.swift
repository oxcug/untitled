//
//  AlertView.swift
//  PanModal
//
//  Created by Stephen Sowole on 3/1/19.
//  Copyright © 2019 Detail. All rights reserved.
//

import UIKit

class AlertView: UIView {

    var icon: UILabel = {
        let icon = UILabel()
        icon.textAlignment = .center
        return icon
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.numberOfLines = 2
        label.textColor = .label
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupView() {
        backgroundColor = .secondarySystemBackground
        layoutIcon()
        layoutStackView()
    }

    private func layoutIcon() {
        addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14).isActive = true
        icon.topAnchor.constraint(equalTo: topAnchor, constant: 14).isActive = true
        icon.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 30).isActive = true
    }

    private func layoutStackView() {
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: icon.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: icon.bottomAnchor).isActive = true
    }
}
