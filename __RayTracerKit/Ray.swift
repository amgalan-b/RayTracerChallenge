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
}
#endif
