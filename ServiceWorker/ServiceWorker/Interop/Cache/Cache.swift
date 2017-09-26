import Foundation
import JavaScriptCore

/// All functions in this protocol should return a Promise resolving to FetchResponse
/// a bool, or string array, depending on function.
@objc public protocol Cache: JSExport {
    func match(_ request: JSValue, _ options: [String: Any]) -> JSValue
    func matchAll(_ request: JSValue, _ options: [String: Any]) -> JSValue
    func add(_ request: JSValue) -> JSValue
    func addAll(_ requests: JSValue) -> JSValue
    func put(_ request: FetchRequest, _ response: FetchResponse) -> JSValue
    func delete(_ request: JSValue, _ options: [String: Any]) -> JSValue
    func keys(_ request: JSValue, _ options: [String: Any]) -> JSValue
}
