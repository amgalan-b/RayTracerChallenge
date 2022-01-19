import Foundation

public final class Triangle: Shape {

    let point1: Tuple
    let point2: Tuple
    let point3: Tuple
    let edge1: Tuple
    let edge2: Tuple
    let normal: Tuple

    public init(_ p1: Tuple, _ p2: Tuple, _ p3: Tuple, material: Material = .default, transform: Matrix = .identity) {
        self.point1 = p1
        self.point2 = p2
        self.point3 = p3
        self.edge1 = p2 - p1
        self.edge2 = p3 - p1
        self.normal = edge2.crossProduct(with: edge1).normalized()
        super.init(material: material, transform: transform)
    }

    override func intersectLocal(with ray: Ray) -> [Intersection] {
        let directionCrossEdge2 = ray.direction.crossProduct(with: edge2)
        let determinant = edge1.dotProduct(with: directionCrossEdge2)

        guard !determinant.isAlmostEqual(to: 0) else {
            return []
        }

        let f = 1.0 / determinant
        let point1ToOrigin = ray.origin - point1
        let u = f * point1ToOrigin.dotProduct(with: directionCrossEdge2)

        guard u >= 0, u <= 1 else {
            return []
        }

        let originCrossEdge1 = point1ToOrigin.crossProduct(with: edge1)
        let v = f * ray.direction.dotProduct(with: originCrossEdge1)

        guard v >= 0, (u + v) <= 1 else {
            return []
        }

        let t = f * edge2.dotProduct(with: originCrossEdge1)
        return [Intersection(time: t, object: self)]
    }

    override func normalLocal(at point: Tuple) -> Tuple {
        return normal
    }

    override func boundingBoxLocal() -> BoundingBox {
        var box = BoundingBox()
        box.addPoint(point1)
        box.addPoint(point2)
        box.addPoint(point3)

        return box
    }
}

#if TEST
import XCTest

final class TriangleTests: XCTestCase {

    func test_triangle() {
        let triangle = Triangle(.point(0, 1, 0), .point(-1, 0, 0), .point(1, 0, 0))

        XCTAssertEqual(triangle.point1, .point(0, 1, 0))
        XCTAssertEqual(triangle.point2, .point(-1, 0, 0))
        XCTAssertEqual(triangle.point3, .point(1, 0, 0))
        XCTAssertEqual(triangle.edge1, .vector(-1, -1, 0))
        XCTAssertEqual(triangle.edge2, .vector(1, -1, 0))
        XCTAssertEqual(triangle.normal, .vector(0, 0, -1))
    }

    func test_normal() {
        let triangle = Triangle(.point(0, 1, 0), .point(-1, 0, 0), .point(1, 0, 0))
        let n1 = triangle.normalLocal(at: .point(0, 0.5, 0))
        let n2 = triangle.normalLocal(at: .point(-0.5, 0.75, 0))
        let n3 = triangle.normalLocal(at: .point(0.5, 0.25, 0))

        XCTAssertEqual(n1, triangle.normal)
        XCTAssertEqual(n2, triangle.normal)
        XCTAssertEqual(n3, triangle.normal)
    }

    func test_intersection_parallel() {
        let triangle = Triangle(.point(0, 1, 0), .point(-1, 0, 0), .point(1, 0, 0))
        let ray = Ray(origin: .point(0, -1, -2), direction: .vector(0, 1, 0))

        XCTAssertEqual(triangle.intersectLocal(with: ray), [])
    }

    func test_intersection_missEdgeP1P3() {
        let triangle = Triangle(.point(0, 1, 0), .point(-1, 0, 0), .point(1, 0, 0))
        let ray = Ray(origin: .point(1, 1, -2), direction: .vector(0, 0, 1))

        XCTAssertEqual(triangle.intersectLocal(with: ray), [])
    }

    func test_intersection_missEdgeP1P2() {
        let triangle = Triangle(.point(0, 1, 0), .point(-1, 0, 0), .point(1, 0, 0))
        let ray = Ray(origin: .point(-1, 1, -2), direction: .vector(0, 0, 1))

        XCTAssertEqual(triangle.intersectLocal(with: ray), [])
    }

    func test_intersection_missEdgeP2P3() {
        let triangle = Triangle(.point(0, 1, 0), .point(-1, 0, 0), .point(1, 0, 0))
        let ray = Ray(origin: .point(0, -1, -2), direction: .vector(0, 0, 1))

        XCTAssertEqual(triangle.intersectLocal(with: ray), [])
    }

    func test_intersection_hit() {
        let triangle = Triangle(.point(0, 1, 0), .point(-1, 0, 0), .point(1, 0, 0))
        let ray = Ray(origin: .point(0, 0.5, -2), direction: .vector(0, 0, 1))
        let times = triangle.intersectLocal(with: ray)
            .map { $0.time }

        XCTAssertEqual(times, [2])
    }

    func test_boundingBox() {
        let triangle = Triangle(.point(-3, 7, 2), .point(6, 2, -4), .point(2, -1, -1))
        let box = triangle.boundingBoxLocal()

        XCTAssertEqual(box.minimum, .point(-3, -1, -4))
        XCTAssertEqual(box.maximum, .point(6, 7, 2))
    }
}
#endif
