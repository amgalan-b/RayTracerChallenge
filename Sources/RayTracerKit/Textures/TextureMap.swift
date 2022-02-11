import Foundation

enum TextureMap: String {

    case spherical
    case planar
    case cylindrical
    case cubic

    func map(point: Point) -> Point2D {
        switch self {
        case .spherical:
            return point._mapSpherical()
        case .planar:
            return point._mapPlanar()
        case .cylindrical:
            return point._mapCylindrical()
        case .cubic:
            return point._mapCubic()
        }
    }
}

extension TextureMap: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        guard let map = TextureMap(rawValue: value) else {
            fatalError()
        }

        self = map
    }
}

extension Point {

    fileprivate func _mapSpherical() -> Point2D {
        let raw_u = atan2(x, z) / (2 * .pi)
        let u = 1 - (raw_u + 0.5)

        let radius = Vector(x, y, z).magnitude
        let phi = acos(y / radius)
        let v = 1 - phi / .pi

        return Point2D(u, v)
    }

    fileprivate func _mapPlanar() -> Point2D {
        let u = x.modulo(dividingBy: 1)
        let v = z.modulo(dividingBy: 1)

        return Point2D(u, v)
    }

    fileprivate func _mapCylindrical() -> Point2D {
        let theta = atan2(x, z)
        let raw_u = theta / (2 * .pi)
        let u = 1 - (raw_u + 0.5)

        let v = y.modulo(dividingBy: 1)

        return Point2D(u, v)
    }

    fileprivate func _mapCubic() -> Point2D {
        guard let face = _CubeFace(point: self) else {
            fatalError()
        }

        return face.map(point: self)
    }
}

private enum _CubeFace {

    case left
    case right
    case front
    case back
    case up
    case down

    init?(point: Point) {
        let coordinate = max(point.x.absoluteValue, point.y.absoluteValue, point.z.absoluteValue)
        switch coordinate {
        case point.x:
            self = .right
        case -point.x:
            self = .left
        case point.y:
            self = .up
        case -point.y:
            self = .down
        case point.z:
            self = .front
        case -point.z:
            self = .back
        default:
            fatalError()
        }
    }

    func map(point: Point) -> Point2D {
        let raw_u: Double
        let raw_v: Double
        switch self {
        case .front:
            raw_u = point.x + 1
            raw_v = point.y + 1
        case .back:
            raw_u = 1 - point.x
            raw_v = point.y + 1
        case .left:
            raw_u = point.z + 1
            raw_v = point.y + 1
        case .right:
            raw_u = 1 - point.z
            raw_v = point.y + 1
        case .up:
            raw_u = point.x + 1
            raw_v = 1 - point.z
        case .down:
            raw_u = point.x + 1
            raw_v = point.z + 1
        }

        let u = raw_u.modulo(dividingBy: 2) / 2
        let v = raw_v.modulo(dividingBy: 2) / 2

        return Point2D(u, v)
    }
}

#if TEST
import XCTest

final class TextureMapTests: XCTestCase {

    func test_mapSpherical() {
        XCTAssertEqual(Point(0, 0, -1)._mapSpherical(), Point2D(0, 0.5))
        XCTAssertEqual(Point(1, 0, 0)._mapSpherical(), Point2D(0.25, 0.5))
        XCTAssertEqual(Point(0, 0, 1)._mapSpherical(), Point2D(0.5, 0.5))
        XCTAssertEqual(Point(-1, 0, 0)._mapSpherical(), Point2D(0.75, 0.5))
        XCTAssertEqual(Point(0, 1, 0)._mapSpherical(), Point2D(0.5, 1))
        XCTAssertEqual(Point(0, -1, 0)._mapSpherical(), Point2D(0.5, 0))
        XCTAssertEqual(Point(sqrt(2) / 2, sqrt(2) / 2, 0)._mapSpherical(), Point2D(0.25, 0.75))
    }

    func test_mapPlanar() {
        XCTAssertEqual(Point(0.25, 0, 0.5)._mapPlanar(), Point2D(0.25, 0.5))
        XCTAssertEqual(Point(0.25, 0, -0.25)._mapPlanar(), Point2D(0.25, 0.75))
        XCTAssertEqual(Point(0.25, 0.5, -0.25)._mapPlanar(), Point2D(0.25, 0.75))
        XCTAssertEqual(Point(1.25, 0, 0.5)._mapPlanar(), Point2D(0.25, 0.5))
        XCTAssertEqual(Point(0.25, 0, -1.75)._mapPlanar(), Point2D(0.25, 0.25))
        XCTAssertEqual(Point(1, 0, -1)._mapPlanar(), Point2D(0, 0))
        XCTAssertEqual(Point(0, 0, 0)._mapPlanar(), Point2D(0, 0))
    }

    func test_mapCylindrical() {
        XCTAssertEqual(Point(0, 0, -1)._mapCylindrical(), Point2D(0, 0))
        XCTAssertEqual(Point(0, 0.5, -1)._mapCylindrical(), Point2D(0, 0.5))
        XCTAssertEqual(Point(0, 1, -1)._mapCylindrical(), Point2D(0, 0))
        XCTAssertEqual(Point(0.70711, 0.5, -0.70711)._mapCylindrical(), Point2D(0.125, 0.5))
        XCTAssertEqual(Point(1, 0.5, 0)._mapCylindrical(), Point2D(0.25, 0.5))
        XCTAssertEqual(Point(0.70711, 0.5, 0.70711)._mapCylindrical(), Point2D(0.375, 0.5))
        XCTAssertEqual(Point(0, -0.25, 1)._mapCylindrical(), Point2D(0.5, 0.75))
        XCTAssertEqual(Point(-0.70711, 0.5, 0.70711)._mapCylindrical(), Point2D(0.625, 0.5))
        XCTAssertEqual(Point(-1, 1.25, 0)._mapCylindrical(), Point2D(0.75, 0.25))
        XCTAssertEqual(Point(-0.70711, 0.5, -0.70711)._mapCylindrical(), Point2D(0.875, 0.5))
    }

    func test_cubeFace_map() {
        XCTAssertEqual(_CubeFace.front.map(point: Point(-0.5, 0.5, 1)), Point2D(0.25, 0.75))
        XCTAssertEqual(_CubeFace.front.map(point: Point(0.5, -0.5, 1)), Point2D(0.75, 0.25))

        XCTAssertEqual(_CubeFace.back.map(point: Point(0.5, 0.5, -1)), Point2D(0.25, 0.75))
        XCTAssertEqual(_CubeFace.back.map(point: Point(-0.5, -0.5, -1)), Point2D(0.75, 0.25))

        XCTAssertEqual(_CubeFace.left.map(point: Point(-1, 0.5, -0.5)), Point2D(0.25, 0.75))
        XCTAssertEqual(_CubeFace.left.map(point: Point(-1, -0.5, 0.5)), Point2D(0.75, 0.25))

        XCTAssertEqual(_CubeFace.right.map(point: Point(1, 0.5, 0.5)), Point2D(0.25, 0.75))
        XCTAssertEqual(_CubeFace.right.map(point: Point(1, -0.5, -0.5)), Point2D(0.75, 0.25))

        XCTAssertEqual(_CubeFace.up.map(point: Point(-0.5, 1, -0.5)), Point2D(0.25, 0.75))
        XCTAssertEqual(_CubeFace.up.map(point: Point(0.5, 1, 0.5)), Point2D(0.75, 0.25))

        XCTAssertEqual(_CubeFace.down.map(point: Point(-0.5, -1, 0.5)), Point2D(0.25, 0.75))
        XCTAssertEqual(_CubeFace.down.map(point: Point(0.5, -1, -0.5)), Point2D(0.75, 0.25))
    }

    func test_cubeFace() {
        XCTAssertEqual(_CubeFace(point: Point(-1, 0.5, -0.25)), .left)
        XCTAssertEqual(_CubeFace(point: Point(1.1, -0.75, 0.8)), .right)
        XCTAssertEqual(_CubeFace(point: Point(0.1, 0.6, 0.9)), .front)
        XCTAssertEqual(_CubeFace(point: Point(-0.7, 0, -2)), .back)
        XCTAssertEqual(_CubeFace(point: Point(0.5, 1, 0.9)), .up)
        XCTAssertEqual(_CubeFace(point: Point(-0.2, -1.3, 1.1)), .down)
    }
}
#endif
