//
//  PokemonsService.swift
//  pokemonObrioAPITest
//
//  Created by airMax on 26.09.2025.
//

import Foundation

struct PokemonListResponse: Decodable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [PokemonListItemDTO]
}

struct PokemonListItemDTO: Decodable {
    let name: String
    let url: String
}

struct PokemonDetailsDTO: Decodable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let sprites: Sprites

    struct Sprites: Decodable {
        let frontDefault: String?
    }
}

struct PokemonListItem: Hashable {
    let id: Int
    let name: String
    let imageURL: URL?
}

struct PokemonDetails: Hashable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let imageURL: URL?
}

protocol PokemonsServiceProtocol {
    func fetchList(offset: Int, limit: Int) async throws -> [PokemonListItem]
    func fetchDetails(id: Int) async throws -> PokemonDetails
}

final class PokemonsService: PokemonsServiceProtocol {
    private let baseURL = URL(string: "https://pokeapi.co/api/v2")!
    private let http: HTTPClientProtocol

    init(http: HTTPClientProtocol = HTTPClient()) {
        self.http = http
    }

    func fetchList(offset: Int, limit: Int) async throws -> [PokemonListItem] {
        var comps = URLComponents(url: baseURL.appendingPathComponent("pokemon"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        let url = comps.url!
        let response: PokemonListResponse = try await http.get(url)
        return response.results.compactMap { dto in
            guard let id = PokemonsService.extractId(from: dto.url) else { return nil }
            let imageURL = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
            return PokemonListItem(id: id, name: dto.name.capitalized, imageURL: imageURL)
        }
    }

    func fetchDetails(id: Int) async throws -> PokemonDetails {
        let url = baseURL.appendingPathComponent("pokemon/\(id)")
        let dto: PokemonDetailsDTO = try await http.get(url)
        let imageURL = dto.sprites.frontDefault.flatMap { URL(string: $0) }
        return PokemonDetails(id: dto.id, name: dto.name.capitalized, height: dto.height, weight: dto.weight, imageURL: imageURL)
    }

    private static func extractId(from urlString: String) -> Int? {
        // URLs look like .../pokemon/1/
        let parts = urlString.split(separator: "/").compactMap { Int($0) }
        return parts.last
    }
}
