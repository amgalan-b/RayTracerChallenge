import Foundation

final class SmoothTriangle: Shape {

    let point1: Tuple
    let point2: Tuple
    let point3: Tuple
    let normal1: Tuple
    let normal2: Tuple
    let normal3: Tuple
    let edge1: Tuple
    let edge2: Tuple

    init(
        _ point1: Tuple,
        _ point2: Tuple,
        _ point3: Tuple,
        _ normal1: Tuple,
        _ normal2: Tuple,
        _ normal3: Tuple,
        material: Material = .default,
        transform: Matrix = .identity
    ) {
        self.point1 = point1
        self.point2 = point2
        self.point3 = point3
        self.normal1 = normal1
        self.normal2 = normal2
        self.normal3 = normal3
        self.edge1 = point2 - point1
        self.edge2 = point3 - point1
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
        return [Intersection(time: t, object: self, additionalData: _IntersectionAdditionalData(u: u, v: v))]
    }

    override func normalLocal(at point: Tuple, additionalData: ShapeIntersectionData? = nil) -> Tuple {
        guard let data = additionalData as? _IntersectionAdditionalData else {
            fatalError()
        }

        return normal2 * data.u
            + normal3 * data.v
            + normal1 * (1 - data.u - data.v)
    }

    override func boundingBoxLocal() -> BoundingBox {
        fatalError()
    }
}

private struct _IntersectionAdditionalData: ShapeIntersectionData {

    let u: Double
    let v: Double
}

#if TEST
import XCTest

final class SmoothTriangleTests: XCTestCase {

    func test_intersection() {
        let triangle = SmoothTriangle(
            .point(0, 1, 0),
            .point(-1, 0, 0),
            .point(1, 0, 0),
            .vector(0, 1, 0),
            .vector(-1, 0, 0),
            .vector(1, 0, 0)
        )
        let ray = Ray(origin: .point(-0.2, 0.3, -2), direction: .vector(0, 0, 1))
        let intersections = triangle.intersectLocal(with: ray)

        guard let additionalData = intersections[0].additionalData as? _IntersectionAdditionalData else {
            return XCTFail()
        }

        XCTAssertEqual(additionalData.u, 0.45, accuracy: .tolerance)
        XCTAssertEqual(additionalData.v, 0.25, accuracy: .tolerance)
    }

    func test_normal() {
        let triangle = SmoothTriangle(
            .point(0, 1, 0),
            .point(-1, 0, 0),
            .point(1, 0, 0),
            .vector(0, 1, 0),
            .vector(-1, 0, 0),
            .vector(1, 0, 0)
        )
        let normal = triangle.normal(at: .point(0, 0, 0), additionalData: _IntersectionAdditionalData(u: 0.45, v: 0.25))

        XCTAssertEqual(normal, .vector(-0.5547, 0.83205, 0))
    }
}
#endif
