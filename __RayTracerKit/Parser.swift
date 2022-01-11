import Foundation

final class Parser {

    var ignoredLineCount = 0
    var vertices = [Tuple]()
    var triangles = [Triangle]()

    func parse(_ input: String) {
        let lines = input.split(whereSeparator: \.isNewline)
            .map { String($0) }

        for line in lines {
            switch _Line(line) {
            case let .vertex(x, y, z):
                vertices.append(.point(x, y, z))
            case let .face(indices):
                let p1 = vertices[indices[0] - 1]
                let p2 = vertices[indices[1] - 1]
                let p3 = vertices[indices[2] - 1]
                let triangle = Triangle(p1, p2, p3)

                triangles.append(triangle)
            case .ignore:
                ignoredLineCount += 1
            }
        }
    }
}

private enum _Line: Equatable {

    case vertex(Double, Double, Double)
    case face(_ indices: [Int])
    case ignore

    init(_ line: String) {
        let parts = line.split(whereSeparator: \.isWhitespace)
            .dropFirst()

        switch line.first {
        case "v":
            let values = parts.compactMap { Double($0) }
            guard values.count == 3 else {
                self = .ignore
                return
            }

            self = .vertex(values[0], values[1], values[2])
        case "f":
            let values = parts.compactMap { Int($0) }
            guard values.count >= 3 else {
                self = .ignore
                return
            }

            self = .face(values)
        default:
            self = .ignore
        }
    }
}

#if TEST
import XCTest

final class LineTests: XCTestCase {

    func test_ignore() {
        let result = _Line("hello world")
        XCTAssertEqual(result, .ignore)
    }

    func test_vertex() {
        let l1 = _Line("v 1 1 0")
        let l2 = _Line("v -1 0 -1")
        let l3 = _Line("v -1.0000 0.5000 0.0000")
        let l4 = _Line("v -1 0 1 0")
        let l5 = _Line("v 1 0")

        XCTAssertEqual(l1, .vertex(1, 1, 0))
        XCTAssertEqual(l2, .vertex(-1, 0, -1))
        XCTAssertEqual(l3, .vertex(-1, 0.5, 0))
        XCTAssertEqual(l4, .ignore)
        XCTAssertEqual(l5, .ignore)
    }

    func test_face() {
        let f1 = _Line("f 1 2 3")
        let f2 = _Line("f 1 3 4")
        let f3 = _Line("f 1 2 3 4 5")
        let f4 = _Line("f")

        XCTAssertEqual(f1, .face([1, 2, 3]))
        XCTAssertEqual(f2, .face([1, 3, 4]))
        XCTAssertEqual(f3, .face([1, 2, 3, 4, 5]))
        XCTAssertEqual(f4, .ignore)
    }
}

final class ParserTests: XCTestCase {

    func test_parse_ignore() {
        let input = """
        There was a young lady named Bright
        who traveled much faster than light.
        She set out one day
        in a relative way,
        and came back the previous night.
        """

        let parser = Parser()
        parser.parse(input)

        XCTAssertEqual(parser.ignoredLineCount, 5)
    }

    func test_parse_vertex() {
        let input = """
        v -1 1 0
        v -1.0000 0.5000 0.0000 v100
        v 1 0 0
        v 1 1 0
        """

        let parser = Parser()
        parser.parse(input)

        XCTAssertEqual(parser.vertices[0], .point(-1, 1, 0))
        XCTAssertEqual(parser.vertices[1], .point(-1, 0.5, 0))
        XCTAssertEqual(parser.vertices[2], .point(1, 0, 0))
        XCTAssertEqual(parser.vertices[3], .point(1, 1, 0))
    }

    func test_parse_face() {
        let input = """
        v -1 1 0
        v -1 0 0
        v 1 0 0
        v 1 1 0
        f 1 2 3
        f 1 3 4
        """

        let parser = Parser()
        parser.parse(input)

        let t1 = parser.triangles[0]
        let t2 = parser.triangles[1]

        XCTAssertEqual(t1.point1, parser.vertices[0])
        XCTAssertEqual(t1.point2, parser.vertices[1])
        XCTAssertEqual(t1.point3, parser.vertices[2])
        XCTAssertEqual(t2.point1, parser.vertices[0])
        XCTAssertEqual(t2.point2, parser.vertices[2])
        XCTAssertEqual(t2.point3, parser.vertices[3])
    }
}

#endif
