import Foundation

var istr: InputStream?
var ostr: OutputStream?
Stream.getStreamsToHost(withName: "localhost", port: 35000, inputStream: &istr, outputStream: &ostr)
let q = StreamCommandQueue(input: istr!, output: ostr!, termination: ">") { }

Task {
    
    do {
        let identification = try await q.send(string: "ATI", timeout: 5)
    } catch {
        print("Can't identify: \(error)")
    }
    
}

while true {
    RunLoop.current.run()
}
