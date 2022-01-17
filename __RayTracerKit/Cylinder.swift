import Foundation

public final class Cylinder: Shape {

    public var minimum = -Double.greatestFiniteMagnitude
    public var maximum = Double.greatestFiniteMagnitude

    public var isCapped = false

    public init(
        material: Material = .default,
        transform: Matrix = .identity,
        minimum: Double = -.greatestFiniteMagnitude,
        maximum: Double = .greatestFiniteMagnitude,
        isCapped: Bool = false
    ) {
        self.minimum = minimum
        self.maximum = maximum
        self.isCapped = isCapped
        super.init(material: material, transform: transform)
    }

    override func intersectLocal(with ray: Ray) -> [Intersection] {
        let a = ray.direction.x.pow(2) + ray.direction.z.pow(2)

        guard !a.isAlmostEqual(to: 0) else {
            return _intersectCaps(ray: ray)
        }

        let b = 2 * ray.origin.x * ray.direction.x + 2 * ray.origin.z * ray.direction.z
        let c = ray.origin.x.pow(2) + ray.origin.z.pow(2) - 1
        let disc = b.pow(2) - 4 * a * c

        guard disc >= 0 else {
            return []
        }

        var intersections = [Intersection]()

        let t0 = (-b - disc.squareRoot()) / (2 * a)
        let y0 = ray.origin.y + t0 * ray.direction.y
        if minimum < y0, y0 < maximum {
            intersections.append(Intersection(time: t0, object: self))
        }

        let t1 = (-b + disc.squareRoot()) / (2 * a)
        let y1 = ray.origin.y + t1 * ray.direction.y
        if minimum < y1, y1 < maximum {
            intersections.append(Intersection(time: t1, object: self))
        }

        return _intersectCaps(ray: ray) + intersections
    }

    override func normalLocal(at point: Tuple) -> Tuple {
        let dist = point.x.pow(2) + point.z.pow(2)
        if dist < 1, point.y >= maximum - .tolerance {
            return .vector(0, 1, 0)
        }

        if dist < 1, point.y <= minimum + .tolerance {
            return .vector(0, -1, 0)
        }

        return .vector(point.x, 0, point.z)
    }

    private func _intersectCaps(ray: Ray) -> [Intersection] {
        if !isCapped || ray.direction.y.isAlmostEqual(to: 0) {
            return []
        }

        var intersections = [Intersection]()

        let t0 = (minimum - ray.origin.y) / ray.direction.y
        if ray._checkCap(time: t0) {
            intersections.append(Intersection(time: t0, object: self))
        }

        let t1 = (maximum - ray.origin.y) / ray.direction.y
        if ray._checkCap(time: t1) {
            intersections.append(Intersection(time: t1, object: self))
        }

        return intersections
    }
}

extension Ray {

    fileprivate func _checkCap(time: Double) -> Bool {
        let x = origin.x + time * direction.x
        let z = origin.z + time * direction.z

        return (x.pow(2) + z.pow(2)) <= 1
    }
}

#if TEST
import XCTest

final class CylinderTests: XCTestCase {

    func test_intersect() {
        let cylinder = Cylinder()

        let xs1 = cylinder._intersectTimes(origin: .point(1, 0, -5), direction: .vector(0, 0, 1))
        let xs2 = cylinder._intersectTimes(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let xs3 = cylinder._intersectTimes(origin: .point(0.5, 0, -5), direction: .vector(0.1, 1, 1))

        XCTAssertEqual(xs1, [5, 5])
        XCTAssertEqual(xs2, [4, 6])
        XCTAssertEqual(xs3, [6.80798, 7.08872], accuracy: .tolerance)
    }

    func test_intersect_miss() {
        let cylinder = Cylinder()

        let xs1 = cylinder._intersectTimes(origin: .point(1, 0, 0), direction: .vector(0, 1, 0))
        let xs2 = cylinder._intersectTimes(origin: .point(0, 0, 0), direction: .vector(0, 1, 0))
        let xs3 = cylinder._intersectTimes(origin: .point(0, 0, -5), direction: .vector(1, 1, 1))

        XCTAssertEqual(xs1, [])
        XCTAssertEqual(xs2, [])
        XCTAssertEqual(xs3, [])
    }

    func test_intersect_constrained() {
        let cylinder = Cylinder(minimum: 1, maximum: 2)

        let xs1 = cylinder._intersectTimes(origin: .point(0, 1.5, 0), direction: .vector(0.1, 1, 0))
        let xs2 = cylinder._intersectTimes(origin: .point(0, 3, -5), direction: .vector(0, 0, 1))
        let xs3 = cylinder._intersectTimes(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let xs4 = cylinder._intersectTimes(origin: .point(0, 2, -5), direction: .vector(0, 0, 1))
        let xs5 = cylinder._intersectTimes(origin: .point(0, 1.5, -2), direction: .vector(0, 0, 1))

        XCTAssertEqual(xs1, [])
        XCTAssertEqual(xs2, [])
        XCTAssertEqual(xs3, [])
        XCTAssertEqual(xs4, [])
        XCTAssertEqual(xs5, [1, 3])
    }

    func test_intersect_capped() {
        let cylinder = Cylinder(minimum: 1, maximum: 2, isCapped: true)

        let xs1 = cylinder._intersectTimes(origin: .point(0, 3, 0), direction: .vector(0, -1, 0))
        let xs2 = cylinder._intersectTimes(origin: .point(0, 3, -2), direction: .vector(0, -1, 2))
        let xs3 = cylinder._intersectTimes(origin: .point(0, 4, -2), direction: .vector(0, -1, 1))
        let xs4 = cylinder._intersectTimes(origin: .point(0, 0, -2), direction: .vector(0, 1, 2))
        let xs5 = cylinder._intersectTimes(origin: .point(0, -1, -2), direction: .vector(0, 1, 1))

        XCTAssertEqual(xs1.count, 2)
        XCTAssertEqual(xs2.count, 2)
        XCTAssertEqual(xs3.count, 2)
        XCTAssertEqual(xs4.count, 2)
        XCTAssertEqual(xs5.count, 2)
    }

    func test_normal() {
        let cylinder = Cylinder()

        XCTAssertEqual(cylinder.normalLocal(at: .point(1, 0, 0)), .vector(1, 0, 0))
        XCTAssertEqual(cylinder.normalLocal(at: .point(0, 5, -1)), .vector(0, 0, -1))
        XCTAssertEqual(cylinder.normalLocal(at: .point(0, -2, 1)), .vector(0, 0, 1))
        XCTAssertEqual(cylinder.normalLocal(at: .point(-1, 1, 0)), .vector(-1, 0, 0))
    }

    func test_normal_capped() {
        let cylinder = Cylinder(minimum: 1, maximum: 2, isCapped: true)

        XCTAssertEqual(cylinder.normalLocal(at: .point(0, 1, 0)), .vector(0, -1, 0))
        XCTAssertEqual(cylinder.normalLocal(at: .point(0.5, 1, 0)), .vector(0, -1, 0))
        XCTAssertEqual(cylinder.normalLocal(at: .point(0, 1, 0.5)), .vector(0, -1, 0))
        XCTAssertEqual(cylinder.normalLocal(at: .point(0, 2, 0)), .vector(0, 1, 0))
        XCTAssertEqual(cylinder.normalLocal(at: .point(0.5, 2, 0)), .vector(0, 1, 0))
        XCTAssertEqual(cylinder.normalLocal(at: .point(0, 2, 0.5)), .vector(0, 1, 0))
    }
}
#endif
