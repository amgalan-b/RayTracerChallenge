import Foundation

extension Parser {

    enum Line: Equatable {

        case vertex(Double, Double, Double)
        case normal(Double, Double, Double)
        case face(_ indices: [Int])
        case smoothFace(_ vertexIndices: [Int], _ normalIndices: [Int])
        case group(_ name: String)
        case ignore

        init(_ line: String) {
            var parts = line.split(whereSeparator: \.isWhitespace)
            switch parts.removeFirst() {
            case "v":
                self = parts._parseVertex()
            case "vn":
                self = parts._parseNormal()
            case "f":
                self = parts._parseFace()
            case "g":
                self = parts._parseGroup()
            default:
                self = .ignore
            }
        }
    }
}

extension Array where Element == Substring {

    fileprivate func _parseVertex() -> Parser.Line {
        let values = compactMap { Double($0) }
        guard values.count == 3 else {
            return .ignore
        }

        return .vertex(values[0], values[1], values[2])
    }

    fileprivate func _parseNormal() -> Parser.Line {
        let values = compactMap { Double($0) }
        guard values.count == 3 else {
            return .ignore
        }

        return .normal(values[0], values[1], values[2])
    }

    fileprivate func _parseGroup() -> Parser.Line {
        guard count == 1 else {
            return .ignore
        }

        return .group(String(first!))
    }

    fileprivate func _parseFace() -> Parser.Line {
        guard let firstPart = first else {
            return .ignore
        }

        guard !firstPart.contains("/") else {
            return _parseSmoothFace()
        }

        let values = compactMap { Int($0) }
        guard values.count >= 3 else {
            return .ignore
        }

        return .face(values)
    }

    fileprivate func _parseSmoothFace() -> Parser.Line {
        let values = map { $0.split(separator: "/", omittingEmptySubsequences: false)
            .map { Int($0) } }

        guard values.count >= 3 else {
            return .ignore
        }

        let vertexIndices = values.compactMap { $0[0] }
        let normalIndices = values.compactMap { $0[2] }

        return .smoothFace(vertexIndices, normalIndices)
    }
}

#if TEST
import XCTest

final class LineTests: XCTestCase {

    private typealias Line = Parser.Line

    func test_ignore() {
        let result = Line("hello world")
        XCTAssertEqual(result, .ignore)
    }

    func test_vertex() {
        let l1 = Line("v 1 1 0")
        let l2 = Line("v -1 0 -1")
        let l3 = Line("v -1.0000 0.5000 0.0000")
        let l4 = Line("v -1 0 1 0")
        let l5 = Line("v 1 0")

        XCTAssertEqual(l1, .vertex(1, 1, 0))
        XCTAssertEqual(l2, .vertex(-1, 0, -1))
        XCTAssertEqual(l3, .vertex(-1, 0.5, 0))
        XCTAssertEqual(l4, .ignore)
        XCTAssertEqual(l5, .ignore)
    }

    func test_face() {
        let f1 = Line("f 1 2 3")
        let f2 = Line("f 1 3 4")
        let f3 = Line("f 1 2 3 4 5")
        let f4 = Line("f")

        XCTAssertEqual(f1, .face([1, 2, 3]))
        XCTAssertEqual(f2, .face([1, 3, 4]))
        XCTAssertEqual(f3, .face([1, 2, 3, 4, 5]))
        XCTAssertEqual(f4, .ignore)
    }

    func test_smoothFace() {
        let f1 = Line("f 1/2/3 2/3/4 3/4/5")
        let f2 = Line("f 1//3 2//4 3//5")

        XCTAssertEqual(f1, .smoothFace([1, 2, 3], [3, 4, 5]))
        XCTAssertEqual(f2, .smoothFace([1, 2, 3], [3, 4, 5]))
    }

    func test_normal() {
        let n1 = Line("vn 0 0 1")
        let n2 = Line("vn 0.707 0 -0.707")
        let n3 = Line("vn")
        let n4 = Line("vn 1")

        XCTAssertEqual(n1, .normal(0, 0, 1))
        XCTAssertEqual(n2, .normal(0.707, 0, -0.707))
        XCTAssertEqual(n3, .ignore)
        XCTAssertEqual(n4, .ignore)
    }
}
#endif
