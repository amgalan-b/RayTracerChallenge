import Babbage
import Foundation

public final class Parser {

    var ignoredLineCount = 0
    var vertices = [Tuple]()
    var triangles = [Triangle]()
    var groups = DefaultDictionary<String, [Triangle]>(defaultValue: [])

    private var _recentGroup: String?

    public init() {
    }

    public func parse(_ input: String) -> Group? {
        let lines = input.split(whereSeparator: \.isNewline)
            .map { String($0) }

        for line in lines {
            switch _Line(line) {
            case let .vertex(x, y, z):
                vertices.append(.point(x, y, z))
            case let .face(indices):
                let newTriangles = indices.map { vertices[$0 - 1] }
                    ._triangulate()

                guard let group = _recentGroup else {
                    triangles += newTriangles
                    continue
                }

                groups[group] += newTriangles
            case let .group(name):
                _recentGroup = name
            case .ignore:
                ignoredLineCount += 1
            }
        }

        let result = Group()
        result.addChildren(triangles)

        for (_, v) in groups.dictionary {
            let group = Group()
            group.addChildren(v)

            result.addChild(group)
        }

        result.constructBoundingVolumeHierarchy(threshold: 1)
        return result
    }
}

extension Array where Element == Tuple {

    fileprivate func _triangulate() -> [Triangle] {
        var triangles = [Triangle]()
        for i in 1 ..< count - 1 {
            let triangle = Triangle(self[0], self[i], self[i + 1])
            triangles.append(triangle)
        }

        return triangles
    }
}

private enum _Line: Equatable {

    case vertex(Double, Double, Double)
    case face(_ indices: [Int])
    case group(_ name: String)
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
        case "g":
            guard parts.count == 1 else {
                self = .ignore
                return
            }

            self = .group(String(parts.first!))
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
        _ = parser.parse(input)

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
        _ = parser.parse(input)

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
        _ = parser.parse(input)

        let t1 = parser.triangles[0]
        let t2 = parser.triangles[1]

        XCTAssertEqual(t1.point1, .point(-1, 1, 0))
        XCTAssertEqual(t1.point2, .point(-1, 0, 0))
        XCTAssertEqual(t1.point3, .point(1, 0, 0))
        XCTAssertEqual(t2.point1, .point(-1, 1, 0))
        XCTAssertEqual(t2.point2, .point(1, 0, 0))
        XCTAssertEqual(t2.point3, .point(1, 1, 0))
    }

    func test_parse_faceTriangulate() {
        let input = """
        v -1 1 0
        v -1 0 0
        v 1 0 0
        v 1 1 0
        v 0 2 0
        f 1 2 3 4 5
        """

        let parser = Parser()
        _ = parser.parse(input)

        let t1 = parser.triangles[0]
        let t2 = parser.triangles[1]
        let t3 = parser.triangles[2]

        XCTAssertEqual(t1.point1, .point(-1, 1, 0))
        XCTAssertEqual(t1.point2, .point(-1, 0, 0))
        XCTAssertEqual(t1.point3, .point(1, 0, 0))
        XCTAssertEqual(t2.point1, .point(-1, 1, 0))
        XCTAssertEqual(t2.point2, .point(1, 0, 0))
        XCTAssertEqual(t2.point3, .point(1, 1, 0))
        XCTAssertEqual(t3.point1, .point(-1, 1, 0))
        XCTAssertEqual(t3.point2, .point(1, 1, 0))
        XCTAssertEqual(t3.point3, .point(0, 2, 0))
    }

    func test_parse_group() {
        let input = """
        v -1 1 0
        v -1 0 0
        v 1 0 0
        v 1 1 0
        g FirstGroup
        f 1 2 3
        g SecondGroup
        f 1 3 4
        """

        let parser = Parser()
        _ = parser.parse(input)

        let g1 = parser.groups["FirstGroup"]
        let g2 = parser.groups["SecondGroup"]

        let t1 = g1[0]
        let t2 = g2[0]

        XCTAssertEqual(t1.point1, .point(-1, 1, 0))
        XCTAssertEqual(t1.point2, .point(-1, 0, 0))
        XCTAssertEqual(t1.point3, .point(1, 0, 0))
        XCTAssertEqual(t2.point1, .point(-1, 1, 0))
        XCTAssertEqual(t2.point2, .point(1, 0, 0))
        XCTAssertEqual(t2.point3, .point(1, 1, 0))
    }

    func test_parse() {
        let input = """
        v -1 1 0
        v -1 0 0
        v 1 0 0
        v 1 1 0
        g FirstGroup
        f 1 2 3
        g SecondGroup
        f 1 3 4
        """

        let parser = Parser()
        let group = parser.parse(input)!

        XCTAssertEqual(group.children.count, 2)
    }
}

#endif
