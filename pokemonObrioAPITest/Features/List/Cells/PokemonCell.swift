//
//  PokemonCell.swift
//  pokemonObrioAPITest
//
//  Created by airMax on 26.09.2025.
//

import UIKit
import SwiftUI

final class PokemonCell: UITableViewCell {
    static let reuseId = "PokemonCell"

    private let spriteView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let nameLabel = UILabel()
    private let idLabel = UILabel()
    private let favoriteButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private var currentToken: UUID?
    private var imageURL: URL?

    var onToggleFavorite: (() -> Void)?
    var onDelete: (() -> Void)?

    private let imageLoader: ImageLoaderProtocol = AppEnvironment.shared.imageLoader

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        if let token = currentToken { imageLoader.cancelLoad(token) }
        currentToken = nil
        spriteView.image = nil
    }

    func configure(with vm: PokemonListCellViewModel) {
        nameLabel.text = vm.name
        idLabel.text = "#\(vm.id)"
        
        let symbolName = vm.isFavorite ? "star.leadinghalf.filled" : "star.slash.fill"
        favoriteButton.setImage(UIImage(systemName: symbolName), for: .normal)
        favoriteButton.tintColor = vm.isFavorite ? .green : .red

        imageURL = vm.imageURL
        spinner.startAnimating()
        if let url = vm.imageURL {
            currentToken = imageLoader.loadImage(from: url) { [weak self] image in
                guard let self, self.imageURL == url else { return }
                self.spriteView.image = image
                self.spinner.stopAnimating()
            }
        } else {
            spriteView.image = nil
            spinner.stopAnimating()
        }
    }

    private func setupUI() {
        spriteView.translatesAutoresizingMaskIntoConstraints = false
        spriteView.contentMode = .scaleAspectFit
        spriteView.widthAnchor.constraint(equalToConstant: 56).isActive = true
        spriteView.heightAnchor.constraint(equalToConstant: 56).isActive = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spriteView.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: spriteView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: spriteView.centerYAnchor)
        ])

        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        idLabel.font = .systemFont(ofSize: 13)
        idLabel.textColor = .secondaryLabel

        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        
        favoriteButton.setImage(UIImage(systemName: "star.slash.fill"), for: .normal)
        
        deleteButton.setTitle("Delete", for: .normal)

        let labels = UIStackView(arrangedSubviews: [nameLabel, idLabel])
        labels.axis = .vertical
        labels.spacing = 4

        let h = UIStackView(arrangedSubviews: [spriteView, labels])
        h.translatesAutoresizingMaskIntoConstraints = false
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12

        contentView.addSubview(h)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(deleteButton)
        
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            h.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            h.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            h.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            favoriteButton.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -16),
            favoriteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            h.trailingAnchor.constraint(lessThanOrEqualTo: favoriteButton.leadingAnchor, constant: -12)
        ])
    }

    @objc private func favoriteTapped() { onToggleFavorite?() }
    @objc private func deleteTapped() { onDelete?() }
}

struct PokemonCell_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerPreview {
            let vc = UIViewController()
            let cell = PokemonCell()
            
            cell.translatesAutoresizingMaskIntoConstraints = false
            vc.view.addSubview(cell)
            
            NSLayoutConstraint.activate([
                cell.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
                cell.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
                cell.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
                cell.heightAnchor.constraint(equalToConstant: 80)
            ])
            
            let mockURL = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png")
            let mockVM = PokemonListCellViewModel(id: 25, name: "Pikachu", imageURL: mockURL, isFavorite: true)
            cell.configure(with: mockVM)
            
            return vc
        }
    }
}
