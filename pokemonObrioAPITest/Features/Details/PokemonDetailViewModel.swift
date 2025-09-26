//
//  PokemonDetailViewModel.swift
//  pokemonObrioAPITest
//
//  Created by airMax on 26.09.2025.
//

import Foundation

@MainActor
final class PokemonDetailViewModel {
    private let service: PokemonsServiceProtocol
    private let favorites: FavoritesStore
    let id: Int

    private(set) var name: String = ""
    private(set) var height: String = ""
    private(set) var weight: String = ""
    private(set) var imageURL: URL?
    private(set) var isFavorite: Bool = false

    var didUpdate: (() -> Void)?
    private var favoritesObserver: UUID?

    init(id: Int, service: PokemonsServiceProtocol, favorites: FavoritesStore) {
        self.id = id
        self.service = service
        self.favorites = favorites
        favoritesObserver = favorites.observe { [weak self] set in
            guard let self else { return }
            Task { @MainActor in
                self.isFavorite = set.contains(id)
                self.didUpdate?()
            }
        }
    }

    deinit {
        if let id = favoritesObserver {
            let favoritesStore = favorites
            Task.detached { @MainActor in
                favoritesStore.removeObserver(id)
            }
        }
    }

    func load() async {
        do {
            let details = try await service.fetchDetails(id: id)
            name = details.name
            height = "Height: \(details.height)"
            weight = "Weight: \(details.weight)"
            imageURL = details.imageURL
            isFavorite = favorites.isFavorite(id)
            didUpdate?()
        } catch {
            // ignore for simplicity
        }
    }

    func toggleFavorite() { favorites.toggle(id) }
}
