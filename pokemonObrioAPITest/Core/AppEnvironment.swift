//
//  AppEnvironment.swift
//  pokemonObrioAPITest
//
//  Created by airMax on 26.09.2025.
//

import Foundation

struct AppEnvironment {
    let service: PokemonsServiceProtocol
    let imageLoader: ImageLoaderProtocol
    let favorites: FavoritesStore

    static let shared = AppEnvironment(
        service: PokemonsService(),
        imageLoader: ImageLoader(),
        favorites: FavoritesStore.shared
    )
}
