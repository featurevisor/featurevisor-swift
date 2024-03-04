import Foundation

extension String {
    
    func removeAllWhitespaces() -> String {
        return String(self.filter { !$0.isWhitespace })
    }
}
