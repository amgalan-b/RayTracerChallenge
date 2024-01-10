import Foundation

extension Array {

    func sorted<T>(by keyPath: KeyPath<Element, T>) -> [Element] where T: Comparable {
        return sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }

    func reduce1(_ makeNext: (Element, Element) -> Element) -> Element? {
        var iterator = makeIterator()
        guard var result = iterator.next() else {
            return nil
        }

        while let element = iterator.next() {
            result = makeNext(result, element)
        }

        return result
    }
}

extension String {

    mutating func popLine() -> Substring? {
        guard let index = firstIndex(where: \.isNewline) else {
            return nil
        }

        let substring = self[startIndex ..< index]
        removeSubrange(startIndex ... index)

        return substring
    }
}
