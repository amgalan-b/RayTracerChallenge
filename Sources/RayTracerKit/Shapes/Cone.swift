import Foundation

public final class Cone: Shape {

    public var minimum = -Double.infinity
    public var maximum = Double.infinity

    public var isCapped = false

    public init(
        minimum: Double = -.infinity,
        maximum: Double = .infinity,
        isCapped: Bool = false,
        material: Material = .default,
        transform: Matrix = .identity
    ) {
        self.minimum = minimum
        self.maximum = maximum
        self.isCapped = isCapped
        super.init(material: material, transform: transform)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        self.minimum = try container.decode(Double.self, forKey: .min)
        self.maximum = try container.decode(Double.self, forKey: .max)
        self.isCapped = try container.decode(Bool.self, forKey: .closed)
        try super.init(from: decoder)
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
            return _intersectCaps(ray: ray) + [Intersection(time: t, object: self)]
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

        return _intersectCaps(ray: ray) + intersections
    }

    override func normalLocal(at point: Point, additionalData: ShapeIntersectionData? = nil) -> Vector {
        let dist = point.x.pow(2) + point.z.pow(2)
        if dist < 1, point.y >= maximum - .tolerance {
            return Vector(0, 1, 0)
        }

        if dist < 1, point.y <= minimum + .tolerance {
            return Vector(0, -1, 0)
        }

        let y = sqrt(point.x.pow(2) + point.z.pow(2))
        guard point.y <= 0 else {
            return Vector(point.x, -y, point.z)
        }

        return Vector(point.x, y, point.z)
    }

    override func boundingBoxLocal() -> BoundingBox {
        let a = minimum.absoluteValue
        let b = maximum.absoluteValue
        let limit = max(a, b)

        return BoundingBox(minimum: Point(-limit, minimum, -limit), maximum: Point(limit, maximum, limit))
    }

    private func _intersectCaps(ray: Ray) -> [Intersection] {
        if !isCapped || ray.direction.y.isAlmostEqual(to: 0) {
            return []
        }

        var intersections = [Intersection]()

        let t0 = (minimum - ray.origin.y) / ray.direction.y
        if ray._checkCap(time: t0, radius: minimum) {
            intersections.append(Intersection(time: t0, object: self))
        }

        let t1 = (maximum - ray.origin.y) / ray.direction.y
        if ray._checkCap(time: t1, radius: maximum) {
            intersections.append(Intersection(time: t1, object: self))
        }

        return intersections
    }
}

extension Cone {

    private enum _CodingKeys: String, CodingKey {

        case min
        case max
        case closed
    }
}

extension Ray {

    fileprivate func _checkCap(time: Double, radius: Double) -> Bool {
        let x = origin.x + time * direction.x
        let z = origin.z + time * direction.z

        return (x.pow(2) + z.pow(2)) <= radius.pow(2)
    }
}

#if TEST
import XCTest

final class ConeTests: XCTestCase {

    func test_intersect() {
        let cone = Cone()

        let r1 = cone._intersectTimes(origin: Point(0, 0, -5), direction: Vector(0, 0, 1))
        let r2 = cone._intersectTimes(origin: Point(0, 0, -5), direction: Vector(1, 1, 1))
        let r3 = cone._intersectTimes(origin: Point(1, 1, -5), direction: Vector(-0.5, -1, 1))

        XCTAssertEqual(r1, [5, 5])
        XCTAssertEqual(r2, [8.66025, 8.66025], accuracy: .tolerance)
        XCTAssertEqual(r3, [4.55006, 49.44994], accuracy: .tolerance)
    }

    func test_intersect_parallel() {
        let cone = Cone()
        let ray = Ray(origin: Point(0, 0, -1), direction: Vector(0, 1, 1).normalized())
        let times = cone.intersectLocal(with: ray)
            .map { $0.time }

        XCTAssertEqual(times, [0.35355], accuracy: .tolerance)
    }

    func test_intersect_capped() {
        let cone = Cone(minimum: -0.5, maximum: 0.5, isCapped: true)

        let r1 = cone._intersectTimes(origin: Point(0, 0, -5), direction: Vector(0, 1, 0).normalized())
        let r2 = cone._intersectTimes(origin: Point(0, 0, -0.25), direction: Vector(0, 1, 1).normalized())
        let r3 = cone._intersectTimes(origin: Point(0, 0, -0.25), direction: Vector(0, 1, 0).normalized())

        XCTAssertEqual(r1, [])
        XCTAssertEqual(r2, [0.7071, 0.08838], accuracy: .tolerance)
        XCTAssertEqual(r3, [-0.5, 0.5, 0.25, -0.25])
    }

    func test_normal() {
        let cone = Cone()

        let r1 = cone.normalLocal(at: Point(0, 0, 0))
        let r2 = cone.normalLocal(at: Point(1, 1, 1))
        let r3 = cone.normalLocal(at: Point(-1, -1, 0))

        XCTAssertEqual(r1, Vector(0, 0, 0))
        XCTAssertEqual(r2, Vector(1, -sqrt(2), 1))
        XCTAssertEqual(r3, Vector(-1, 1, 0))
    }

    func test_boundingBox() {
        let cone = Cone(minimum: -5, maximum: 3)
        let box = cone.boundingBoxLocal()

        XCTAssertEqual(box.minimum, Point(-5, -5, -5))
        XCTAssertEqual(box.maximum, Point(5, 3, 5))
    }
}
#endif
