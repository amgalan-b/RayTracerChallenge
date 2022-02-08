import Foundation

extension UnkeyedDecodingContainer {

    mutating func decodeArray<T>(of type: T.Type) throws -> [T] where T: Decodable {
        var result = [T]()
        while !isAtEnd {
            result.append(try decode(T.self))
        }

        return result
    }
}
