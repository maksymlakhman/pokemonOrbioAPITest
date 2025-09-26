//
//  FavoritesStore.swift
//  pokemonObrioAPITest
//
//  Created by airMax on 26.09.2025.
//

import Foundation

final class FavoritesStore {
    static let shared = FavoritesStore()

    private var favorites: Set<Int> = []
    private let queue = DispatchQueue(label: "favorites.store.queue", attributes: .concurrent)
    private var observers: [UUID: (Set<Int>) -> Void] = [:]

    func isFavorite(_ id: Int) -> Bool {
        var result = false
        queue.sync { result = favorites.contains(id) }
        return result
    }

    func toggle(_ id: Int) {
        queue.async(flags: .barrier) {
            if self.favorites.contains(id) { self.favorites.remove(id) } else { self.favorites.insert(id) }
            let snapshot = self.favorites
            DispatchQueue.main.async { self.notify(snapshot) }
        }
    }

    func remove(_ id: Int) {
        queue.async(flags: .barrier) {
            self.favorites.remove(id)
            let snapshot = self.favorites
            DispatchQueue.main.async { self.notify(snapshot) }
        }
    }

    func count() -> Int {
        var c = 0
        queue.sync { c = favorites.count }
        return c
    }

    func snapshot() -> Set<Int> {
        var set: Set<Int> = []
        queue.sync { set = favorites }
        return set
    }

    @discardableResult
    func observe(_ handler: @escaping (Set<Int>) -> Void) -> UUID {
        let id = UUID()
        observers[id] = handler
        handler(current())
        return id
    }

    func removeObserver(_ id: UUID) {
        observers[id] = nil
    }

    private func current() -> Set<Int> {
        var snapshot: Set<Int> = []
        queue.sync { snapshot = favorites }
        return snapshot
    }

    private func notify(_ set: Set<Int>) {
        for cb in observers.values { cb(set) }
    }
}
