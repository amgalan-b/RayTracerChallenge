import Foundation

public class Shape {

    public var material: Material
    public var transform: Matrix

    public init(material: Material = .default, transform: Matrix = .identity) {
        self.material = material
        self.transform = transform
    }

    final func intersect(with ray: Ray) -> [Intersection] {
        let localRay = ray.transformed(with: transform.inversed())
        return intersectLocal(with: localRay)
    }

    final func normal(at worldPoint: Tuple) -> Tuple {
        let objectPoint = transform.inversed() * worldPoint
        let objectNormal = normalLocal(at: objectPoint)
        let worldNormal = transform.inversed().transposed() * objectNormal

        return Tuple(worldNormal.x, worldNormal.y, worldNormal.z, 0).normalized()
    }

    func intersectLocal(with ray: Ray) -> [Intersection] {
        fatalError()
    }

    func normalLocal(at point: Tuple) -> Tuple {
        fatalError()
    }
}

extension Shape: Equatable {

    public static func == (lhs: Shape, rhs: Shape) -> Bool {
        return lhs === rhs
    }
}

extension Shape: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

private final class _TestShape: Shape {

    fileprivate var _ray: Ray?

    override func intersectLocal(with ray: Ray) -> [Intersection] {
        _ray = ray
        return []
    }

    override func normalLocal(at point: Tuple) -> Tuple {
        return Tuple.vector(point.x, point.y, point.z)
    }
}

#if TEST
import XCTest

final class ShapeTests: XCTestCase {

    func test_defaults() {
        let shape = _TestShape()
        XCTAssertEqual(shape.transform, .identity)
    }

    func test_transform() {
        let shape = _TestShape(transform: .translation(2, 3, 4))
        XCTAssertEqual(shape.transform, .translation(2, 3, 4))
    }

    func test_intersect_scaledShape() {
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let shape = _TestShape(transform: .scaling(2, 2, 2))
        _ = shape.intersect(with: ray)

        XCTAssertEqual(shape._ray, Ray(origin: .point(0, 0, -2.5), direction: .vector(0, 0, 0.5)))
    }

    func test_intersect_translatedShape() {
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let shape = _TestShape(transform: .translation(5, 0, 0))
        _ = shape.intersect(with: ray)

        XCTAssertEqual(shape._ray, Ray(origin: .point(-5, 0, -5), direction: .vector(0, 0, 1)))
    }

    func test_normal_translatedShape() {
        let shape = _TestShape(transform: .translation(0, 1, 0))
        let normal = shape.normal(at: .point(0, 1.70711, -0.70711))

        XCTAssertEqual(normal, .vector(0, 0.70711, -0.70711))
    }

    func test_normal_arbitraryTransform() {
        let shape = _TestShape(transform: .scaling(1, 0.5, 1) * .rotationZ(.pi / 5))
        let normal = shape.normal(at: .point(0, 0.7071, -0.7071))

        XCTAssertEqual(normal, .vector(0, 0.97014, -0.24254))
    }
}

extension Shape {

    func _intersectTimes(origin: Tuple, direction: Tuple) -> [Double] {
        return intersectLocal(with: Ray(origin: origin, direction: direction.normalized()))
            .map { $0.time }
    }
}
#endif
