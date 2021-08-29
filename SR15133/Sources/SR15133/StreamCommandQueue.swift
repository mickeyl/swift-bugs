import Foundation

/// Error conditions while sending and receiving over the stream
public enum StreamError: Error {
    case communication /// A low-level error while opening, sending, receiving, or closing the underlying IOStream
    case timeout /// The request was not answered within the specified time
    case invalidEncoding /// The peer returned data with an invalid encoding
}
/// The continuation type to be stored in a ``StreamCommand``.
typealias Continuation = CheckedContinuation<String, Error>

/// Represents a single command to be sent over the stream
public class StreamCommand {

    private enum State {
        case created
        case transmitting
        case transmitted
        case responding
        case completed
        case failed
    }

    private var outputBuffer: [UInt8] = []
    private var inputBuffer: [UInt8] = []
    private var tempBuffer: [UInt8] = .init(repeating: 0, count: 8192)
    private var state: State = .created {
        didSet {
            print("state now \(state)")
        }
    }
    private let continuation: Continuation
    let termination: [UInt8]
    let timeout: TimeInterval
    let timer: DispatchSourceTimer

    var canWrite: Bool { self.state == .created || self.state == .transmitting }
    var canRead: Bool { self.state == .transmitted || self.state == .responding }
    var isCompleted: Bool { self.state == .completed }

    init(string: String, timeout: TimeInterval, termination: String, continuation: Continuation, timeoutHandler: @escaping( () -> Void)) {
        self.outputBuffer = Array(string.utf8)
        self.termination = Array(termination.utf8)
        self.timeout = timeout
        self.continuation = continuation
        self.timer = DispatchSource.makeTimerSource()
        self.timer.setEventHandler { timeoutHandler() }
    }

    func write(to stream: OutputStream) {
        precondition(self.canWrite)
        self.state = .transmitting

        let written = stream.write(&outputBuffer, maxLength: outputBuffer.count)
        outputBuffer.removeFirst(written)
        print("wrote \(written) bytes")
        if outputBuffer.isEmpty {
            self.state = .transmitted
            self.timer.schedule(deadline: .now() + self.timeout)
            self.timer.resume()
        }
    }

    func read(from stream: InputStream) {
        precondition(self.canRead)
        self.state = .responding

        let read = stream.read(&self.tempBuffer, maxLength: self.tempBuffer.count)
        print("read \(read) bytes")
        self.inputBuffer += self.tempBuffer[0..<read]
        guard let terminationRange = self.inputBuffer.lastRange(of: self.termination) else {
            return
        }
        self.timer.cancel()
        self.inputBuffer.removeLast(terminationRange.count)
        self.state = .completed
    }

    func resumeContinuation(throwing error: StreamError? = nil) {

        if let error = error {
            self.state = .failed
            self.continuation.resume(throwing: error)
            return
        }
        guard let response = String(bytes: self.inputBuffer, encoding: .utf8) else {
            Task.detached { self.continuation.resume(throwing: StreamError.invalidEncoding) }
            return
        }
        Task.detached { self.continuation.resume(returning: response) }
    }
}

public actor StreamCommandQueue: NSObject {

    let input: InputStream
    let output: OutputStream
    var pendingCommands: [StreamCommand] = []
    var activeCommand: StreamCommand?
    let termination: String
    //let errorHandler: ()->Void

    init(input: InputStream, output: OutputStream, termination: String = "", errorhandler: @escaping( ()->Void )) {
        precondition(Thread.isMainThread, "StreamCommandQueue must be created from within the main thread, otherwise we don't have a runloop to process events in.")

        self.input = input
        self.output = output
        self.termination = termination
        //self.errorHandler = errorhandler

        super.init()

        self.input.delegate = self
        self.output.delegate = self
        /* Note: This will schedule the input and the output streams for processing their handles in the main thread.
         * In most cases this should not be a problem, although we might consider to spin a secondary thread just for the
         * purpose of keeping _everything_ from the main thread. */
        self.input.schedule(in: RunLoop.current, forMode: .common)
        self.output.schedule(in: RunLoop.current, forMode: .common)

        self.input.open()
    }

    func send(string: String, timeout: TimeInterval) async throws -> String {

        let response: String = try await withCheckedThrowingContinuation { continuation in
            self.activeCommand = StreamCommand(string: string, timeout: timeout, termination: self.termination, continuation: continuation) {
                self.timeoutActiveCommand()
            }
            self.outputActiveCommand()
        }
        return response
    }
    
}

//MARK:- Helpers
private extension StreamCommandQueue {

    func outputActiveCommand() {

        guard self.output.streamStatus == .open else { return self.output.open() }
        guard self.output.hasSpaceAvailable else { return }
        guard let command = self.activeCommand else { fatalError() }
        guard command.canWrite else {
            print("command sent, waiting for response...")
            return
        }
        command.write(to: self.output)
    }

    func inputActiveCommand() {

        guard self.input.streamStatus == .open else { return }
        guard self.input.hasBytesAvailable else { return }
        guard let command = self.activeCommand else { fatalError("received unsolicited bytes") }
        guard command.canRead else {
            print("command not ready for reading...")
            return
        }
        command.read(from: self.input)
        if command.isCompleted {
            command.resumeContinuation()
        }
        self.activeCommand = nil
    }
    
    func timeoutActiveCommand() {
        guard let command = self.activeCommand else { fatalError("received timeout for non-existing command") }
        print("command timed out after \(command.timeout) seconds.")
        command.resumeContinuation(throwing: .timeout)
        self.activeCommand = nil
    }
    
    func handleErrorCondition(stream: Stream, event: Stream.Event) {
        print("error encountered")
        self.input.delegate = nil
        self.output.delegate = nil
        if let command = self.activeCommand {
            command.resumeContinuation(throwing: .communication)
            self.activeCommand = nil // this triggers EXC_BREAKPOINT in _dispatch_queue_xref_dispose.cold.2
        }

    }
}

extension StreamCommandQueue: StreamDelegate {

    nonisolated public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        print("received stream \(aStream), event \(eventCode) in thread \(Thread.current)")

        switch (aStream, eventCode) {
            case (self.output, .hasSpaceAvailable):
                Task.detached { await self.outputActiveCommand() }

            case (self.input, .hasBytesAvailable):
                Task.detached { await self.inputActiveCommand() }
                
            case (_, .errorOccurred):
                fallthrough
            case (_, .endEncountered):
                Task.detached { await self.handleErrorCondition(stream: aStream, event: eventCode) }

            default:
                print("unhandled \(aStream): \(eventCode)")
                break
        }
    }
}

