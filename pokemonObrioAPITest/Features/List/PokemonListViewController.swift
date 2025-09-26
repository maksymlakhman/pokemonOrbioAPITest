//
//  PokemonListViewController.swift
//  pokemonObrioAPITest
//
//  Created by airMax on 26.09.2025.
//

import UIKit
import SwiftUI

final class PokemonListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activity = UIActivityIndicatorView(style: .medium)
    private let env = AppEnvironment.shared
    private lazy var viewModel = PokemonListViewModel(service: env.service, favorites: env.favorites)
    private var favoritesObserver: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavBar()
        setupTable()
        bindVM()
        Task { await viewModel.refresh() }
    }

    private func setupNavBar() {
        title = "Pokémon"
        updateFavoritesBadge(count: env.favorites.count())
        favoritesObserver = env.favorites.observe { [weak self] set in
            self?.updateFavoritesBadge(count: set.count)
        }
    }

    private func updateFavoritesBadge(count: Int) {
        let btn = UIButton(type: .system)
        btn.setTitle("★ \(count)", for: .normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btn)
    }

    private func bindVM() {
        viewModel.didUpdate = { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(PokemonCell.self, forCellReuseIdentifier: PokemonCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PokemonCell.reuseId, for: indexPath) as! PokemonCell
        let vm = viewModel.items[indexPath.row]
        cell.configure(with: vm)
        cell.onToggleFavorite = { [weak self] in self?.viewModel.toggleFavorite(at: indexPath.row) }
        cell.onDelete = { [weak self] in
            self?.viewModel.delete(at: indexPath.row)
        }
        return cell
    }

    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let id = viewModel.items[indexPath.row].id
        let vc = PokemonDetailViewController(pokemonId: id)
        navigationController?.pushViewController(vc, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isDragging || scrollView.isDecelerating else { return }
        if let last = tableView.indexPathsForVisibleRows?.last {
            Task { await viewModel.loadNextPageIfNeeded(currentIndex: last.row) }
        }
    }
}

struct PokemonListViewController_Previews: PreviewProvider {
  static var previews: some View {
    ViewControllerPreview {
        PokemonListViewController()
    }
  }
}
