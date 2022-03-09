//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

typealias Continuation = CheckedContinuation<String, Error>

public enum StreamError: Error {
    case invalidEncoding
}

public class StreamCommand {

    let continuation: Continuation

    init(continuation: Continuation) {
        self.continuation = continuation
    }

    func resumeContinuation() {
        let response = "fooBar"
        print("<triggering continuation resume> \(self.continuation)")
        self.continuation.resume(returning: response)
        print("</triggering continuation resume>")
    }
}

actor StreamCommandQueue {

    var activeCommand: StreamCommand?

    func send(string: String, timeout: TimeInterval) async throws -> String {

        print("awaiting...")
        let response: String = try await withCheckedThrowingContinuation { continuation in
            print("continuation: \(continuation)")
            self.activeCommand = StreamCommand(continuation: continuation)
            self.outputActiveCommand()
        }
        
        print("came back after awaiting")
        return response
    }

    func outputActiveCommand() {
        async {
            self.activeCommand!.resumeContinuation()
        }
    }

    func inputActiveCommand() {

    }
}

func doIt() {

    async {
        let streamQueue = StreamCommandQueue()
        do {
            let identification = try await streamQueue.send(string: "ATI\r", timeout: 1)
            print("identification: \(identification)")
        } catch {
            print("can't get identification: \(error)")
        }
    }

}

