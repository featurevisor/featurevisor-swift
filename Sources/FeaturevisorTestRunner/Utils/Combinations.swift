import Foundation

enum Combinations {

    static func combine<T>(lists: [[T]], partial: [T] = []) -> [[T]] {

        guard !lists.isEmpty else {
            return [partial]
        }

        var lists = lists
        let first = lists.removeFirst()
        var result = [[T]]()

        for n in first {
            result += combine(lists: lists, partial: partial + [n])
        }

        return result
    }
}
