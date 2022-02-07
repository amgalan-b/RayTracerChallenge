import Babbage
import Foundation

public final class OBJParser {

    fileprivate var _ignoredLineCount = 0
    fileprivate var _vertices = [Point]()
    fileprivate var _normals = [Vector]()
    fileprivate var _topLevelShapes = [Shape]()
    fileprivate var _topLevelGroups = DefaultDictionary<String, [Shape]>(defaultValue: [])

    private var _recentGroup: String?

    public init() {
    }

    public func parse(_ input: String, isBoundingVolumeHierarchyEnabled: Bool = false) -> Group {
        let lines = input.split(whereSeparator: \.isNewline)
            .map { String($0) }

        for line in lines {
            switch Line(line) {
            case let .vertex(x, y, z):
                _vertices.append(Point(x, y, z))
            case let .normal(dx, dy, dz):
                _normals.append(Vector(dx, dy, dz))
            case let .face(indices):
                let newTriangles = indices.map { _vertices[$0 - 1] }
                    ._triangulate()

                guard let group = _recentGroup else {
                    _topLevelShapes += newTriangles
                    continue
                }

                _topLevelGroups[group] += newTriangles
            case let .smoothFace(vertexIndices, normalIndices):
                let newTriangles = vertexIndices.map { _vertices[$0 - 1] }
                    ._smoothTriangulate(normals: normalIndices.map { _normals[$0 - 1] })

                guard let group = _recentGroup else {
                    _topLevelShapes += newTriangles
                    continue
                }

                _topLevelGroups[group] += newTriangles
            case let .group(name):
                _recentGroup = name
            case .ignore:
                _ignoredLineCount += 1
            }
        }

        print("Ignored: \(_ignoredLineCount)", to: &standardError)

        let result = Group()
        result.addChildren(_topLevelShapes)

        for (_, shapes) in _topLevelGroups.dictionary {
            let group = Group()
            group.addChildren(shapes)

            result.addChild(group)
        }

        if isBoundingVolumeHierarchyEnabled {
            result.constructBoundingVolumeHierarchy(threshold: 1)
        }

        return result
    }
}

extension Array where Element == Point {

    fileprivate func _triangulate() -> [Triangle] {
        var triangles = [Triangle]()
        for i in 1 ..< count - 1 {
            let triangle = Triangle(self[0], self[i], self[i + 1])
            triangles.append(triangle)
        }

        return triangles
    }

    fileprivate func _smoothTriangulate(normals: [Vector]) -> [SmoothTriangle] {
        var triangles = [SmoothTriangle]()
        for i in 1 ..< count - 1 {
            let triangle = SmoothTriangle(self[0], self[i], self[i + 1], normals[0], normals[i], normals[i + 1])
            triangles.append(triangle)
        }

        return triangles
    }
}

#if TEST
import XCTest

final class ParserTests: XCTestCase {

    func test_parse_ignore() {
        let input = """
        There was a young lady named Bright
        who traveled much faster than light.
        She set out one day
        in a relative way,
        and came back the previous night.
        """

        let parser = OBJParser()
        _ = parser.parse(input)

        XCTAssertEqual(parser._ignoredLineCount, 5)
    }

    func test_parse_vertex() {
        let input = """
        v -1 1 0
        v -1.0000 0.5000 0.0000 v100
        v 1 0 0
        v 1 1 0
        """

        let parser = OBJParser()
        _ = parser.parse(input)

        XCTAssertEqual(parser._vertices[0], Point(-1, 1, 0))
        XCTAssertEqual(parser._vertices[1], Point(-1, 0.5, 0))
        XCTAssertEqual(parser._vertices[2], Point(1, 0, 0))
        XCTAssertEqual(parser._vertices[3], Point(1, 1, 0))
    }

    func test_parse_normal() {
        let input = """
        vn 0 0 1
        vn 0.707 0 -0.707
        vn 1 2 3
        """

        let parser = OBJParser()
        _ = parser.parse(input)

        XCTAssertEqual(parser._normals[0], Vector(0, 0, 1))
        XCTAssertEqual(parser._normals[1], Vector(0.707, 0, -0.707))
        XCTAssertEqual(parser._normals[2], Vector(1, 2, 3))
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

        let parser = OBJParser()
        _ = parser.parse(input)

        let t1 = parser._topLevelShapes[0] as! Triangle
        let t2 = parser._topLevelShapes[1] as! Triangle

        XCTAssertEqual(t1.point1, Point(-1, 1, 0))
        XCTAssertEqual(t1.point2, Point(-1, 0, 0))
        XCTAssertEqual(t1.point3, Point(1, 0, 0))
        XCTAssertEqual(t2.point1, Point(-1, 1, 0))
        XCTAssertEqual(t2.point2, Point(1, 0, 0))
        XCTAssertEqual(t2.point3, Point(1, 1, 0))
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

        let parser = OBJParser()
        _ = parser.parse(input)

        let t1 = parser._topLevelShapes[0] as! Triangle
        let t2 = parser._topLevelShapes[1] as! Triangle
        let t3 = parser._topLevelShapes[2] as! Triangle

        XCTAssertEqual(t1.point1, Point(-1, 1, 0))
        XCTAssertEqual(t1.point2, Point(-1, 0, 0))
        XCTAssertEqual(t1.point3, Point(1, 0, 0))
        XCTAssertEqual(t2.point1, Point(-1, 1, 0))
        XCTAssertEqual(t2.point2, Point(1, 0, 0))
        XCTAssertEqual(t2.point3, Point(1, 1, 0))
        XCTAssertEqual(t3.point1, Point(-1, 1, 0))
        XCTAssertEqual(t3.point2, Point(1, 1, 0))
        XCTAssertEqual(t3.point3, Point(0, 2, 0))
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

        let parser = OBJParser()
        _ = parser.parse(input)

        let g1 = parser._topLevelGroups["FirstGroup"]
        let g2 = parser._topLevelGroups["SecondGroup"]

        let t1 = g1[0] as! Triangle
        let t2 = g2[0] as! Triangle

        XCTAssertEqual(t1.point1, Point(-1, 1, 0))
        XCTAssertEqual(t1.point2, Point(-1, 0, 0))
        XCTAssertEqual(t1.point3, Point(1, 0, 0))
        XCTAssertEqual(t2.point1, Point(-1, 1, 0))
        XCTAssertEqual(t2.point2, Point(1, 0, 0))
        XCTAssertEqual(t2.point3, Point(1, 1, 0))
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

        let parser = OBJParser()
        let group = parser.parse(input)

        XCTAssertEqual(group.children.count, 2)
    }
}
#endif
