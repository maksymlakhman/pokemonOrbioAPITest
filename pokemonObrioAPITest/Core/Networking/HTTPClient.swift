//
//  HTTPClient.swift
//  pokemonObrioAPITest
//
//  Created by airMax on 26.09.2025.
//

import Foundation

protocol HTTPClientProtocol {
    func get<T: Decodable>(_ url: URL) async throws -> T
    func getData(_ url: URL) async throws -> Data
}

final class HTTPClient: HTTPClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        try HTTPClient.validate(response: response)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    func getData(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        try HTTPClient.validate(response: response)
        return data
    }

    private static func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
}
