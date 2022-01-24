import Babbage
import Collections

extension Array where Element == Intersection {

    func hit() -> Intersection? {
        return sorted(by: \.time)
            .first { $0.time >= 0 }
    }

    func refractiveIndices(hit: Intersection) -> RefractiveIndices {
        var n1 = 1.0
        var n2 = 1.0

        var objects = OrderedSet<Shape>()
        for intersection in self {
            if intersection == hit {
                n1 = objects.last?.material.refractiveIndex ?? 1.0
            }

            if objects.contains(intersection.object) {
                objects.remove(intersection.object)
            } else {
                objects.append(intersection.object)
            }

            if intersection == hit {
                n2 = objects.last?.material.refractiveIndex ?? 1.0
                break
            }
        }

        return [n1, n2]
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

    func test_refractiveIndices() {
        let s1 = Sphere(material: .default(refractiveIndex: 1.5), transform: .scaling(2, 2, 2))
        let s2 = Sphere(material: .default(refractiveIndex: 2), transform: .translation(0, 0, -0.25))
        let s3 = Sphere(material: .default(refractiveIndex: 2.5), transform: .translation(0, 0, 0.25))

        let intersections = [
            Intersection(time: 2, object: s1),
            Intersection(time: 2.75, object: s2),
            Intersection(time: 3.25, object: s3),
            Intersection(time: 4.75, object: s2),
            Intersection(time: 5.25, object: s3),
            Intersection(time: 6, object: s1),
        ]

        let refractiveIndices = intersections
            .map { intersections.refractiveIndices(hit: $0) }

        XCTAssertEqual(refractiveIndices, [[1.0, 1.5], [1.5, 2.0], [2.0, 2.5], [2.5, 2.5], [2.5, 1.5], [1.5, 1.0]])
    }
}
#endif
