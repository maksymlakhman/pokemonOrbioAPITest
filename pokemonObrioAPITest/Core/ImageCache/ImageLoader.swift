//
//  ImageLoader.swift
//  pokemonObrioAPITest
//
//  Created by airMax on 26.09.2025.
//

import UIKit

protocol ImageLoaderProtocol {
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) -> UUID?
    func cancelLoad(_ token: UUID)
}

final class ImageLoader: ImageLoaderProtocol {
    private let cache = LRUImageCache(maxImages: 20)
    private var runningTasks: [UUID: URLSessionDataTask] = [:]
    private let lock = NSLock()

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) -> UUID? {
        if let image = cache.image(for: url) {
            completion(image)
            return nil
        }

        let token = UUID()
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            var resultImage: UIImage? = nil
            if let data, let image = UIImage(data: data) {
                self?.cache.insert(image, for: url)
                resultImage = image
            }
            DispatchQueue.main.async {
                completion(resultImage)
            }
            self?.lock.lock()
            self?.runningTasks[token] = nil
            self?.lock.unlock()
        }
        lock.lock()
        runningTasks[token] = task
        lock.unlock()
        task.resume()
        return token
    }

    func cancelLoad(_ token: UUID) {
        lock.lock()
        let task = runningTasks[token]
        runningTasks[token] = nil
        lock.unlock()
        task?.cancel()
    }
}

final class LRUImageCache {
    private struct Node {
        let key: URL
        var value: UIImage
    }

    private let maxImages: Int
    private var dict: [URL: UIImage] = [:]
    private var order: [URL] = [] // most-recent at end
    private let lock = NSLock()

    init(maxImages: Int) {
        self.maxImages = maxImages
    }

    func image(for key: URL) -> UIImage? {
        lock.lock(); defer { lock.unlock() }
        guard let image = dict[key] else { return nil }
        touch(key)
        return image
    }

    func insert(_ image: UIImage, for key: URL) {
        lock.lock(); defer { lock.unlock() }
        dict[key] = image
        touch(key)
        evictIfNeeded()
    }

    private func touch(_ key: URL) {
        if let idx = order.firstIndex(of: key) {
            order.remove(at: idx)
        }
        order.append(key)
    }

    private func evictIfNeeded() {
        while dict.count > maxImages, let oldest = order.first {
            dict[oldest] = nil
            order.removeFirst()
        }
    }
}
