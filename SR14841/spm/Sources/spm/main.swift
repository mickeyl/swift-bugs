import Foundation

let q = StreamCommandQueue()
Task.init {
    doIt()
}
Thread.sleep(forTimeInterval: 5)
print("Hello, world!")
