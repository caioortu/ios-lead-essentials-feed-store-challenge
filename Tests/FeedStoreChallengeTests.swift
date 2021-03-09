//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge

class UserDefaultsFeedStore: FeedStore {
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
	
	init(userDefaults: UserDefaults = .standard, storeKey: String = "feedStoreKey") {
		self.userDefaults = userDefaults
		self.storeKey = storeKey
	}
	
	func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		guard userDefaults.object(forKey: storeKey) != nil else {
			return completion(nil)
		}
		
		userDefaults.removeObject(forKey: storeKey)
		completion(nil)
	}
	
	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
		do {
			let data = try JSONEncoder().encode(cache)
			self.userDefaults.set(data, forKey: self.storeKey)
			completion(nil)
		} catch {
			completion(error)
		}
	}
	
	func retrieve(completion: @escaping RetrievalCompletion) {
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

class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {
	
	//  ***********************
	//
	//  Follow the TDD process:
	//
	//  1. Uncomment and run one test at a time (run tests with CMD+U).
	//  2. Do the minimum to make the test pass and commit.
	//  3. Refactor if needed and commit again.
	//
	//  Repeat this process until all tests are passing.
	//
	//  ***********************
	
	override func setUpWithError() throws {
		try super.setUpWithError()
		
		try setupEmptyStoreState()
	}
	
	override func tearDownWithError() throws {
		try undoStoreSideEffects()
		
		try super.tearDownWithError()
	}
	
	func test_retrieve_deliversEmptyOnEmptyCache() throws {
		let sut = try makeSUT()
		
		assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_retrieve_deliversFoundValuesOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_insert_overridesPreviouslyInsertedCacheValues() throws {
		let sut = try makeSUT()

		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}
	
	func test_delete_deliversNoErrorOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_delete_hasNoSideEffectsOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_delete_deliversNoErrorOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_delete_emptiesPreviouslyInsertedCache() throws {
		let sut = try makeSUT()

		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}
	
	func test_storeSideEffects_runSerially() throws {
		let sut = try makeSUT()

		assertThatSideEffectsRunSerially(on: sut)
	}
	
	// - MARK: Helpers
	
	private func makeSUT(userDefaults: UserDefaults? = nil, storeKey: String? = nil) throws -> FeedStore {
		let sut = UserDefaultsFeedStore(userDefaults: userDefaults ?? specificForTestUserDefaults(),
										storeKey: storeKey ?? specificForTestStoreKey())
		
		return sut
	}
	
	private func setupEmptyStoreState() throws {
		deleteStoreArtifacts()
	}
	
	private func undoStoreSideEffects() throws {
		deleteStoreArtifacts()
	}
	
	private func deleteStoreArtifacts() {
		let userDefaults = specificForTestUserDefaults()
		userDefaults.dictionaryRepresentation().forEach { key, _ in
			userDefaults.removeObject(forKey: key)
		}
	}
	
	private func specificForTestUserDefaults() -> UserDefaults {
		return UserDefaults(suiteName: "\(type(of: self)).store")!
	}
	
	private func specificForTestStoreKey() -> String {
		return "\(type(of: self)).storeKey"
	}
	
}

//  ***********************
//
//  Uncomment the following tests if your implementation has failable operations.
//
//  Otherwise, delete the commented out code!
//
//  ***********************

extension FeedStoreChallengeTests: FailableRetrieveFeedStoreSpecs {

	func test_retrieve_deliversFailureOnRetrievalError() throws {
		let userDefaults = specificForTestUserDefaults()
		let storeKey = specificForTestStoreKey()
		let invalidData = Data("invalid data".utf8)
		let sut = try makeSUT()

		userDefaults.set(invalidData, forKey: storeKey)

		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure() throws {
		let userDefaults = specificForTestUserDefaults()
		let storeKey = specificForTestStoreKey()
		let invalidData = Data("invalid data".utf8)
		let sut = try makeSUT()

		userDefaults.set(invalidData, forKey: storeKey)

		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}

}
