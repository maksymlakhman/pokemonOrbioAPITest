//
//  PokemonDetailViewController.swift
//  pokemonObrioAPITest
//
//  Created by airMax on 26.09.2025.
//

import UIKit
import SwiftUI

final class PokemonDetailViewController: UIViewController {
    private let env = AppEnvironment.shared
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let heightLabel = UILabel()
    private let weightLabel = UILabel()
    private let favoriteButton = UIButton(type: .system)
    private var token: UUID?

    private let viewModel: PokemonDetailViewModel

    init(pokemonId: Int) {
        self.viewModel = PokemonDetailViewModel(id: pokemonId, service: env.service, favorites: env.favorites)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        bind()
        Task { await viewModel.load() }
    }

    private func setupUI() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        heightLabel.font = .systemFont(ofSize: 16)
        weightLabel.font = .systemFont(ofSize: 16)

        favoriteButton.addTarget(self, action: #selector(favTapped), for: .touchUpInside)

        let v = UIStackView(arrangedSubviews: [imageView, nameLabel, heightLabel, weightLabel, favoriteButton])
        v.translatesAutoresizingMaskIntoConstraints = false
        v.axis = .vertical
        v.alignment = .center
        v.spacing = 12

        view.addSubview(v)
        NSLayoutConstraint.activate([
            v.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            v.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func bind() {
        viewModel.didUpdate = { [weak self] in
            guard let self else { return }
            self.title = self.viewModel.name
            self.nameLabel.text = self.viewModel.name
            self.heightLabel.text = self.viewModel.height
            self.weightLabel.text = self.viewModel.weight
            self.favoriteButton.setImage(UIImage(systemName: self.viewModel.isFavorite ? "medal.star.fill" : "medal.star"), for: .normal)
            self.favoriteButton.tintColor = self.viewModel.isFavorite ? .green : .red
            self.favoriteButton.setTitle(self.viewModel.isFavorite ? "Remove Favorite" : "Add Favorite", for: .normal)
            if let url = self.viewModel.imageURL {
                self.token = self.env.imageLoader.loadImage(from: url) { [weak self] image in
                    self?.imageView.image = image
                }
            }
        }
    }

    @objc private func favTapped() { viewModel.toggleFavorite() }
}

struct PokemonDetailViewController_Previews: PreviewProvider {
  static var previews: some View {
    ViewControllerPreview {
        PokemonDetailViewController(pokemonId: 25)
    }
  }
}
