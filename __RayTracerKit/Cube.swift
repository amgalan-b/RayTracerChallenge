import Foundation

public final class Cube: Shape {

    override func intersectLocal(with ray: Ray) -> [Intersection] {
        return Self.intersectionTimes(for: ray, minimum: .point(-1, -1, -1), maximum: .point(1, 1, 1))
            .map { Intersection(time: $0, object: self) }
    }

    override func normalLocal(at point: Tuple) -> Tuple {
        switch max(point.x.absoluteValue, point.y.absoluteValue, point.z.absoluteValue) {
        case point.x.absoluteValue:
            return .vector(point.x, 0, 0)
        case point.y.absoluteValue:
            return .vector(0, point.y, 0)
        case point.z.absoluteValue:
            return .vector(0, 0, point.z)
        default:
            fatalError()
        }
    }

    override func boundingBoxLocal() -> BoundingBox {
        return BoundingBox(minimum: .point(-1, -1, -1), maximum: .point(1, 1, 1))
    }
}

extension Cube {

    /// - Note: Also used for bounding box intersections.
    static func intersectionTimes(for ray: Ray, minimum: Tuple, maximum: Tuple) -> [Double] {
        let (xtmin, xtmax) = Self._checkAxis(
            origin: ray.origin.x,
            direction: ray.direction.x,
            minimum: minimum.x,
            maximum: maximum.x
        )
        let (ytmin, ytmax) = Self._checkAxis(
            origin: ray.origin.y,
            direction: ray.direction.y,
            minimum: minimum.y,
            maximum: maximum.y
        )
        let (ztmin, ztmax) = Self._checkAxis(
            origin: ray.origin.z,
            direction: ray.direction.z,
            minimum: minimum.z,
            maximum: maximum.z
        )

        let tmin = max(xtmin, ytmin, ztmin)
        let tmax = min(xtmax, ytmax, ztmax)

        guard tmin <= tmax else {
            return []
        }

        return [tmin, tmax]
    }

    fileprivate static func _checkAxis(
        origin: Double,
        direction: Double,
        minimum: Double,
        maximum: Double
    ) -> (Double, Double) {
        let tminNumerator = (minimum - origin)
        let tmaxNumerator = maximum - origin

        let tmin: Double
        let tmax: Double
        if direction.absoluteValue >= .tolerance {
            tmin = tminNumerator / direction
            tmax = tmaxNumerator / direction
        } else {
            tmin = tminNumerator * .infinity
            tmax = tmaxNumerator * .infinity
        }

        guard tmin <= tmax else {
            return (tmax, tmin)
        }

        return (tmin, tmax)
    }
}

#if TEST
import XCTest

final class CubeTests: XCTestCase {

    func test_intersection() {
        XCTAssertEqual(_intersectionTimes(origin: .point(5, 0.5, 0), direction: .vector(-1, 0, 0)), [4, 6])
        XCTAssertEqual(_intersectionTimes(origin: .point(-5, 0.5, 0), direction: .vector(1, 0, 0)), [4, 6])
        XCTAssertEqual(_intersectionTimes(origin: .point(0.5, 5, 0), direction: .vector(0, -1, 0)), [4, 6])
        XCTAssertEqual(_intersectionTimes(origin: .point(0.5, -5, 0), direction: .vector(0, 1, 0)), [4, 6])
        XCTAssertEqual(_intersectionTimes(origin: .point(0.5, 0, 5), direction: .vector(0, 0, -1)), [4, 6])
        XCTAssertEqual(_intersectionTimes(origin: .point(0.5, 0, -5), direction: .vector(0, 0, 1)), [4, 6])
        XCTAssertEqual(_intersectionTimes(origin: .point(0, 0.5, 0), direction: .vector(0, 0, 1)), [-1, 1])
    }

    func test_intersection_miss() {
        XCTAssertEqual(_intersectionTimes(origin: .point(-2, 0, 0), direction: .vector(0.2673, 0.5345, 0.8018)), [])
        XCTAssertEqual(_intersectionTimes(origin: .point(0, -2, 0), direction: .vector(0.8018, 0.2673, 0.5345)), [])
        XCTAssertEqual(_intersectionTimes(origin: .point(0, 0, -2), direction: .vector(0.5345, 0.8018, 0.2673)), [])
        XCTAssertEqual(_intersectionTimes(origin: .point(2, 0, 2), direction: .vector(0, 0, -1)), [])
        XCTAssertEqual(_intersectionTimes(origin: .point(0, 2, 2), direction: .vector(0, -1, 0)), [])
        XCTAssertEqual(_intersectionTimes(origin: .point(2, 2, 0), direction: .vector(-1, 0, 0)), [])
    }

    func test_normal() {
        let cube = Cube()

        XCTAssertEqual(cube.normalLocal(at: .point(1, 0.5, -0.8)), .vector(1, 0, 0))
        XCTAssertEqual(cube.normalLocal(at: .point(-1, -0.2, 0.9)), .vector(-1, 0, 0))
        XCTAssertEqual(cube.normalLocal(at: .point(-0.4, 1, -0.1)), .vector(0, 1, 0))
        XCTAssertEqual(cube.normalLocal(at: .point(0.3, -1, -0.7)), .vector(0, -1, 0))
        XCTAssertEqual(cube.normalLocal(at: .point(-0.6, 0.3, 1)), .vector(0, 0, 1))
        XCTAssertEqual(cube.normalLocal(at: .point(0.4, 0.4, -1)), .vector(0, 0, -1))
        XCTAssertEqual(cube.normalLocal(at: .point(1, 1, 1)), .vector(1, 0, 0))
        XCTAssertEqual(cube.normalLocal(at: .point(-1, -1, -1)), .vector(-1, 0, 0))
    }

    func test_boundingBox() {
        let cube = Cube()
        let box = cube.boundingBoxLocal()

        XCTAssertEqual(box.minimum, .point(-1, -1, -1))
        XCTAssertEqual(box.maximum, .point(1, 1, 1))
    }

    private func _intersectionTimes(origin: Tuple, direction: Tuple) -> [Double] {
        let cube = Cube()
        let ray = Ray(origin: origin, direction: direction)
        return cube.intersectLocal(with: ray)
            .map { $0.time }
    }
}
#endif
