import Foundation

struct Intersection {

    let time: Double
    let object: Sphere
}

extension Intersection: Equatable {
}

extension Array where Element == Intersection {

    func hit() -> Intersection? {
        return sorted(by: \.time)
            .first { $0.time >= 0 }
    }
}

#if TEST
import XCTest

final class IntersectionArrayTests: XCTestCase {

    func test_hit_allHavePositiveTime() {
        let sphere = Sphere()
        let i1 = Intersection(time: 1, object: sphere)
        let i2 = Intersection(time: 2, object: sphere)

        XCTAssertEqual([i1, i2].hit(), i1)
    }

    func test_hit_someHaveNegativeTime() {
        let sphere = Sphere()
        let i1 = Intersection(time: -1, object: sphere)
        let i2 = Intersection(time: 1, object: sphere)

        XCTAssertEqual([i1, i2].hit(), i2)
    }

    func test_hit_allHaveNegativeTime() {
        let sphere = Sphere()
        let i1 = Intersection(time: -2, object: sphere)
        let i2 = Intersection(time: -1, object: sphere)

        XCTAssertNil([i1, i2].hit())
    }

    func test_hit_lowestPositiveTime() {
        let sphere = Sphere()
        let i1 = Intersection(time: 5, object: sphere)
        let i2 = Intersection(time: 7, object: sphere)
        let i3 = Intersection(time: -3, object: sphere)
        let i4 = Intersection(time: 2, object: sphere)

        XCTAssertEqual([i1, i2, i3, i4].hit(), i4)
    }
}
#endif
