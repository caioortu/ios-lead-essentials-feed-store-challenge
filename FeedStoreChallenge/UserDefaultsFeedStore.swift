//
//  UserDefaultsFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Caio Ortu on 3/8/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public final class UserDefaultsFeedStore: FeedStore {
	private let storeKey: String
	private let userDefaults: UserDefaults
	
	private struct Cache: Codable {
		let feed: [CodableFeedImage]
		let timestamp: Date
		
		var localFeed: [LocalFeedImage] {
			return feed.map { $0.local }
		}
	}
	
	private struct CodableFeedImage: Codable {
		private let id: UUID
		private let description: String?
		private let location: String?
		private let url: URL
		
		init(_ image: LocalFeedImage) {
			id = image.id
			description = image.description
			location = image.location
			url = image.url
		}
		
		var local: LocalFeedImage {
			return LocalFeedImage(id: id, description: description, location: location, url: url)
		}
	}
	
	public init(userDefaults: UserDefaults = .standard, storeKey: String = "feedStoreKey") {
		self.userDefaults = userDefaults
		self.storeKey = storeKey
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		userDefaults.removeObject(forKey: storeKey)
		completion(nil)
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
		do {
			let data = try JSONEncoder().encode(cache)
			self.userDefaults.set(data, forKey: self.storeKey)
			completion(nil)
		} catch {
			completion(error)
		}
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		guard let data = userDefaults.data(forKey: storeKey) else {
			return completion(.empty)
		}
		do {
			let cache = try JSONDecoder().decode(Cache.self, from: data)
			completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
		} catch {
			completion(.failure(error))
		}
	}
}
