import Foundation

struct Ray {

    let origin: Point
    let direction: Vector

    init(origin: Point, direction: Vector) {
        self.origin = origin
        self.direction = direction
    }

    func position(at time: Double) -> Point {
        return origin + direction * time
    }

    func transformed(with transformation: Matrix) -> Self {
        return Ray(origin: transformation * origin, direction: transformation * direction)
    }
}

extension Ray: Equatable {
}

#if TEST
import XCTest

final class RayTests: XCTestCase {

    func test_position() {
        let ray = Ray(origin: Point(2, 3, 4), direction: Vector(1, 0, 0))

        XCTAssertEqual(ray.position(at: 0), Point(2, 3, 4))
        XCTAssertEqual(ray.position(at: 1), Point(3, 3, 4))
        XCTAssertEqual(ray.position(at: -1), Point(1, 3, 4))
        XCTAssertEqual(ray.position(at: 2.5), Point(4.5, 3, 4))
    }

    func test_transformed_translation() {
        let ray = Ray(origin: Point(1, 2, 3), direction: Vector(0, 1, 0))
            .transformed(with: .translation(3, 4, 5))
        let expected = Ray(origin: Point(4, 6, 8), direction: Vector(0, 1, 0))

        XCTAssertEqual(ray, expected)
    }

    func test_transformed_scaling() {
        let ray = Ray(origin: Point(1, 2, 3), direction: Vector(0, 1, 0))
            .transformed(with: .scaling(2, 3, 4))
        let expected = Ray(origin: Point(2, 6, 12), direction: Vector(0, 3, 0))

        XCTAssertEqual(ray, expected)
    }
}
#endif
