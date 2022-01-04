import Foundation

final class Cone: Shape {

    public var minimum = -Double.infinity
    public var maximum = Double.infinity

    public var isCapped = false

    public init(
        material: Material = .default,
        transform: Matrix = .identity,
        minimum: Double = -.infinity,
        maximum: Double = .infinity,
        isCapped: Bool = false
    ) {
        self.minimum = minimum
        self.maximum = maximum
        self.isCapped = isCapped
        super.init(material: material, transform: transform)
    }

    override func intersectLocal(with ray: Ray) -> [Intersection] {
        let o = ray.origin
        let d = ray.direction

        let a = d.x.pow(2) - d.y.pow(2) + d.z.pow(2)
        let b = 2 * o.x * d.x - 2 * o.y * d.y + 2 * o.z * d.z
        let c = o.x.pow(2) - o.y.pow(2) + o.z.pow(2)

        if a.isAlmostEqual(to: 0, tolerance: .tolerance), b.isAlmostEqual(to: 0, tolerance: .tolerance) {
            return []
        }

        guard !a.isAlmostEqual(to: 0, tolerance: .tolerance) else {
            let t = -c / (2 * b)
            return [Intersection(time: t, object: self)]
        }

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

        return intersections
    }

    override func normalLocal(at point: Tuple) -> Tuple {
        return .vector(0, 0, 0)
    }
}

#if TEST
import XCTest

final class ConeTests: XCTestCase {

    func test_intersect() {
        let cone = Cone()

        let r1 = cone._intersectTimes(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let r2 = cone._intersectTimes(origin: .point(0, 0, -5), direction: .vector(1, 1, 1))
        let r3 = cone._intersectTimes(origin: .point(1, 1, -5), direction: .vector(-0.5, -1, 1))

        XCTAssertEqual(r1, [5, 5])
        XCTAssertEqual(r2, [8.66025, 8.66025], accuracy: .tolerance)
        XCTAssertEqual(r3, [4.55006, 49.44994], accuracy: .tolerance)
    }

    func test_intersect_parallel() {
        let cone = Cone()
        let ray = Ray(origin: .point(0, 0, -1), direction: .vector(0, 1, 1).normalized())
        let times = cone.intersectLocal(with: ray)
            .map { $0.time }

        XCTAssertEqual(times, [0.35355], accuracy: .tolerance)
    }
}
#endif
