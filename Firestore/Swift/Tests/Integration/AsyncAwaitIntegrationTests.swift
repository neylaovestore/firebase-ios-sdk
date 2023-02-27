/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation
import FirebaseFirestore.FIRAggregateField

let emptyBundle = """
{\
   "metadata":{\
      "id":"test",\
      "createTime":{\
         "seconds":0,\
         "nanos":0\
      },\
      "version":1,\
      "totalDocuments":0,\
      "totalBytes":0\
   }\
}
"""

#if swift(>=5.5.2)
  @available(iOS 13, tvOS 13, macOS 10.15, macCatalyst 13, watchOS 7, *)
  class AsyncAwaitIntegrationTests: FSTIntegrationTestCase {
    func testAddData() async throws {
      let collection = collectionRef()
      let document = try await collection.addDocument(data: [:])
      let snapshot = try await document.getDocument()
      XCTAssertTrue(snapshot.exists)
    }

    func testLoadBundleFromData() async throws {
      let bundle = "\(emptyBundle.count)\(emptyBundle)"
      let bundleProgress = try await db.loadBundle(Data(bundle.utf8))
      XCTAssertEqual(LoadBundleTaskState.success, bundleProgress.state)
    }

    func testLoadBundleFromEmptyDataFails() async throws {
      do {
        _ = try await db.loadBundle(Data())
        XCTFail("Bundle loading should have failed")
      } catch {
        XCTAssertEqual((error as NSError).domain, FirestoreErrorDomain)
        XCTAssertEqual((error as NSError).code, FirestoreErrorCode.unknown.rawValue)
      }
    }

    func testLoadBundleFromStream() async throws {
      let bundle = "\(emptyBundle.count)\(emptyBundle)"
      let bundleProgress = try await db
        .loadBundle(InputStream(data: bundle.data(using: String.Encoding.utf8)!))
      XCTAssertEqual(LoadBundleTaskState.success, bundleProgress.state)
    }

    func testRunTransactionDoesNotCrashOnNilSuccess() async throws {
      let value = try await db.runTransaction { transact, error in
        nil // should not crash
      }

      XCTAssertNil(value, "value should be nil on success")
    }

      func testCount() async throws {
        let collection = collectionRef()
        try await collection.addDocument(data: [:])
        let snapshot = try await collection.count.getAggregation(source: .server)
        XCTAssertEqual(snapshot.count, 1)
      }

      func testSum() async throws {
          let collection = collectionRef()
          let sumOfFoo = AggregateField.sum("foo");

          try await collection.addDocument(data: [:])
          let snapshot = try await collection.aggregate([sumOfFoo]).getAggregation(source: .server)

          XCTAssertEqual(try snapshot.getDouble(sumOfFoo), 100.5)
          XCTAssertEqual(try snapshot.getLong(sumOfFoo), 100)
          XCTAssertEqual(try snapshot.get(sumOfFoo) as? Int64, 100)
      }
  }
#endif
