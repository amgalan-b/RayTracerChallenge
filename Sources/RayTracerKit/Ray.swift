import Foundation

struct Ray {

    let origin: Tuple
    let direction: Tuple

    init(origin: Tuple, direction: Tuple) {
        assert(origin.isPoint && direction.isVector)
        self.origin = origin
        self.direction = direction
    }

    func position(at time: Double) -> Tuple {
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
        let ray = Ray(origin: .point(2, 3, 4), direction: .vector(1, 0, 0))

        XCTAssertEqual(ray.position(at: 0), .point(2, 3, 4))
        XCTAssertEqual(ray.position(at: 1), .point(3, 3, 4))
        XCTAssertEqual(ray.position(at: -1), .point(1, 3, 4))
        XCTAssertEqual(ray.position(at: 2.5), .point(4.5, 3, 4))
    }

    func test_transformed_translation() {
        let ray = Ray(origin: .point(1, 2, 3), direction: .vector(0, 1, 0))
            .transformed(with: .translation(3, 4, 5))
        let expected = Ray(origin: .point(4, 6, 8), direction: .vector(0, 1, 0))

        XCTAssertEqual(ray, expected)
    }

    func test_transformed_scaling() {
        let ray = Ray(origin: .point(1, 2, 3), direction: .vector(0, 1, 0))
            .transformed(with: .scaling(2, 3, 4))
        let expected = Ray(origin: .point(2, 6, 12), direction: .vector(0, 3, 0))

        XCTAssertEqual(ray, expected)
    }
}
#endif
