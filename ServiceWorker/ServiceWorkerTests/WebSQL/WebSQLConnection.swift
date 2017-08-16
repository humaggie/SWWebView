//
//  WebSQLConnection.swift
//  ServiceWorkerTests
//
//  Created by alastair.coote on 04/08/2017.
//  Copyright © 2017 Guardian Mobile Innovation Lab. All rights reserved.
//

import XCTest
@testable import ServiceWorker
import PromiseKit

class WebSQLConnectionTests: XCTestCase {
    
    let webSQLTestPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("websql", isDirectory: true)
    
    override func setUp() {
        super.setUp()
        do {
            if FileManager.default.fileExists(atPath: self.webSQLTestPath.path) {
                try FileManager.default.removeItem(atPath: self.webSQLTestPath.path)
            }
            try FileManager.default.createDirectory(at: self.webSQLTestPath, withIntermediateDirectories: true, attributes: nil)
            
            ServiceWorker.storageURL = self.webSQLTestPath
            
        } catch {
            XCTFail("\(error)")
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func injectOpenDBIntoWorker(_ sw:ServiceWorker) -> Promise<Void> {
        return sw.withJSContext { context in
            
            let open = WebSQLDatabase.createOpenDatabaseFunction(for: sw.url)
            context.globalObject.setValue(open, forProperty: "openDatabase")
            
        }
    }
    
    func testOpeningDatabase() {
        
        let sw = ServiceWorker.createTestWorker()
        
        self.injectOpenDBIntoWorker(sw)
            .then {
                return sw.evaluateScript("""
                    (function() {
                        var db = openDatabase('test', 1, 'pretty name', 1024);
                        return typeof db.transaction !== 'undefined'}
                )()
                """)
        }
            .then { jsResult -> Void in
                XCTAssertEqual(jsResult?.toBool(), true)
            }
            .assertResolves()
        
    }
    
    func testTransactionCallback() {
        
        let sw = ServiceWorker.createTestWorker()
        
        self.injectOpenDBIntoWorker(sw)
            .then {
                return sw.evaluateScript("""
                    var db = openDatabase('test', 1, 'pretty name', 1024);
                    new Promise(function(fulfill, reject) {

                        var callbackCalled = false;

                        db.transaction(function(tx) {
                            callbackCalled = true;
                        }, function() {
                            fulfill(callbackCalled)
                        })

                    })
                """)
            }
            .then { jsResult in
                return JSPromise.fromJSValue(jsResult!)
            }
            .then { promiseResult in
                XCTAssertEqual(promiseResult?.toBool(), true)
            }
            .assertResolves()

    }
    
    func testResultSetSelect() {
        
        let sw = ServiceWorker.createTestWorker()
        
        self.injectOpenDBIntoWorker(sw)
            .then {
                return sw.evaluateScript("""
                    var db = openDatabase('test', 1, 'pretty name', 1024);
                    new Promise(function(fulfill, reject) {

                       db.transaction(function(tx) {
                            
                            tx.executeSql("SELECT 'test' as textval", [], function(results) {
                                fulfill(results.rows[0].textval)
                            }, function() {
                               
                            })
                        }, function() {
                        })

                    })
                """)
            }
            .then { jsResult in
                return JSPromise.fromJSValue(jsResult!)
            }
            .then { promiseResult in
                XCTAssertEqual(promiseResult?.toString(), "test")
            }
            .assertResolves()
        
    }

    
}
