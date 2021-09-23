import Foundation
import CornucopiaStreams

var istr: InputStream?
var ostr: OutputStream?

#if canImport(FoundationNetworking)
let (istream, ostream) = Stream.CC_getStreamsToHost(with: "localhost", port: 35000)
assert(istream != nil)
assert(ostream != nil)
istr = istream
ostr = ostream
#else
Stream.getStreamsToHost(withName: "localhost", port: 35000, inputStream: &istr, outputStream: &ostr)
#endif
let q = StreamCommandQueue(input: istr!, output: ostr!, termination: ">") { }

Task {
    
    do {
        let reset = try await q.send(string: "ATZ\r", timeout: 5)
        let identification = try await q.send(string: "ATI\r", timeout: 5)
        print("reset: \(reset)")
        print("identification: \(identification)")
    } catch {
        print("Can't identify: \(error)")
    }
    
}

while true {
    RunLoop.current.run()
}
