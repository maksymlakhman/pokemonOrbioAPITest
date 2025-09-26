//
//  PokemonListViewModel.swift
//  pokemonObrioAPITest
//
//  Created by airMax on 26.09.2025.
//

import Foundation

struct PokemonListCellViewModel: Hashable {
    let id: Int
    let name: String
    let imageURL: URL?
    var isFavorite: Bool
}

@MainActor
final class PokemonListViewModel {
    private let service: PokemonsServiceProtocol
    private let favorites: FavoritesStore

    private(set) var items: [PokemonListCellViewModel] = []
    private var offset: Int = 0
    private let pageSize: Int = 20
    private var isLoading: Bool = false
    private var favoritesObserver: UUID?

    var didUpdate: (() -> Void)?

    init(service: PokemonsServiceProtocol, favorites: FavoritesStore) {
        self.service = service
        self.favorites = favorites
        favoritesObserver = favorites.observe { [weak self] set in
            guard let self else { return }
            Task { @MainActor in
                self.items = self.items.map { vm in
                    var m = vm
                    m.isFavorite = set.contains(vm.id)
                    return m
                }
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

    func loadNextPageIfNeeded(currentIndex: Int) async {
        guard currentIndex >= items.count - 5 else { return }
        await loadPage()
    }

    func refresh() async {
        offset = 0
        items = []
        await loadPage()
    }

    func delete(at index: Int) {
        guard items.indices.contains(index) else { return }
        let removed = items.remove(at: index)
        // If deleted item was in favorites, remove it to keep counter in sync
        if favorites.isFavorite(removed.id) {
            favorites.remove(removed.id)
        }
        didUpdate?()
    }

    func toggleFavorite(at index: Int) {
        guard items.indices.contains(index) else { return }
        favorites.toggle(items[index].id)
    }

    private func loadPage() async {
        guard !isLoading else { return }
        isLoading = true
        do {
            let list = try await service.fetchList(offset: offset, limit: pageSize)
            let currentFavs = favorites.snapshot()
            let new = list.map { item in
                PokemonListCellViewModel(
                    id: item.id,
                    name: item.name,
                    imageURL: item.imageURL,
                    isFavorite: currentFavs.contains(item.id)
                )
            }
            items.append(contentsOf: new)
            offset += pageSize
            didUpdate?()
        } catch {
            // catch
        }
        isLoading = false
    }

}
