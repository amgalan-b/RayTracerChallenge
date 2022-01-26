import Foundation

final class CSG: Shape {

    let left: Shape
    let right: Shape
    let operation: Operation

    init(_ left: Shape, _ right: Shape, operation: Operation) {
        self.left = left
        self.right = right
        self.operation = operation
    }

    override func intersectLocal(with ray: Ray) -> [Intersection] {
        let intersections = left.intersect(with: ray) + right.intersect(with: ray)
        return _filter(intersections: intersections.sorted(by: \.time))
    }

    override func includes(_ shape: Shape) -> Bool {
        return left == shape || right == shape
    }

    fileprivate func _filter(intersections: [Intersection]) -> [Intersection] {
        var isInsideLeft = false
        var isInsideRight = false
        var result = [Intersection]()

        for intersection in intersections {
            let isHitLeft = left.includes(intersection.object)
            if operation.isIntersectionAllowed(isHitLeft, isInsideLeft: isInsideLeft, isInsideRight: isInsideRight) {
                result.append(intersection)
            }

            if isHitLeft {
                isInsideLeft.toggle()
            } else {
                isInsideRight.toggle()
            }
        }

        return result
    }
}

extension CSG {

    enum Operation {

        case union
        case intersect
        case difference

        func isIntersectionAllowed(_ isHitleft: Bool, isInsideLeft: Bool, isInsideRight: Bool) -> Bool {
            switch self {
            case .union:
                return (isHitleft && !isInsideRight) || (!isHitleft && !isInsideLeft)
            case .intersect:
                return (isHitleft && isInsideRight) || (!isHitleft && isInsideLeft)
            case .difference:
                return (isHitleft && !isInsideRight) || (!isHitleft && isInsideLeft)
            }
        }
    }
}

#if TEST
import XCTest

final class CSGTests: XCTestCase {

    typealias Operation = CSG.Operation

    func test_intersectionAllowed() {
        let r1 = Operation.union.isIntersectionAllowed(true, isInsideLeft: true, isInsideRight: true)
        let r2 = Operation.union.isIntersectionAllowed(true, isInsideLeft: true, isInsideRight: false)
        let r3 = Operation.union.isIntersectionAllowed(true, isInsideLeft: false, isInsideRight: true)
        let r4 = Operation.union.isIntersectionAllowed(true, isInsideLeft: false, isInsideRight: false)
        let r5 = Operation.union.isIntersectionAllowed(false, isInsideLeft: true, isInsideRight: true)
        let r6 = Operation.union.isIntersectionAllowed(false, isInsideLeft: true, isInsideRight: false)
        let r7 = Operation.union.isIntersectionAllowed(false, isInsideLeft: false, isInsideRight: true)
        let r8 = Operation.union.isIntersectionAllowed(false, isInsideLeft: false, isInsideRight: false)

        XCTAssertEqual(r1, false)
        XCTAssertEqual(r2, true)
        XCTAssertEqual(r3, false)
        XCTAssertEqual(r4, true)
        XCTAssertEqual(r5, false)
        XCTAssertEqual(r6, false)
        XCTAssertEqual(r7, true)
        XCTAssertEqual(r8, true)
    }

    func test_filter() {
        let s1 = Sphere()
        let s2 = Cube()
        let intersections = [
            Intersection(time: 1, object: s1),
            Intersection(time: 2, object: s2),
            Intersection(time: 3, object: s1),
            Intersection(time: 4, object: s2),
        ]

        let r1 = CSG(s1, s2, operation: .union)
            ._filter(intersections: intersections)

        let r2 = CSG(s1, s2, operation: .intersect)
            ._filter(intersections: intersections)

        let r3 = CSG(s1, s2, operation: .difference)
            ._filter(intersections: intersections)

        XCTAssertEqual(r1, [intersections[0], intersections[3]])
        XCTAssertEqual(r2, [intersections[1], intersections[2]])
        XCTAssertEqual(r3, [intersections[0], intersections[1]])
    }

    func test_intersect_miss() {
        let s1 = Sphere()
        let s2 = Cube()
        let csg = CSG(s1, s2, operation: .union)
        let ray = Ray(origin: .point(0, 2, -5), direction: .vector(0, 0, 1))

        XCTAssertEqual(csg.intersectLocal(with: ray), [])
    }

    func test_intersect() {
        let s1 = Sphere()
        let s2 = Sphere(transform: .translation(0, 0, 0.5))
        let csg = CSG(s1, s2, operation: .union)
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let expected = [Intersection(time: 4, object: s1), Intersection(time: 6.5, object: s2)]

        XCTAssertEqual(csg.intersectLocal(with: ray), expected)
    }
}
#endif
