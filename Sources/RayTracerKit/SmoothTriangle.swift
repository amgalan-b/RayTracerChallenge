import Foundation

final class SmoothTriangle: Triangle {

    let normal1: Vector
    let normal2: Vector
    let normal3: Vector

    init(
        _ point1: Point,
        _ point2: Point,
        _ point3: Point,
        _ normal1: Vector,
        _ normal2: Vector,
        _ normal3: Vector,
        material: Material = .default,
        transform: Matrix = .identity
    ) {
        self.normal1 = normal1
        self.normal2 = normal2
        self.normal3 = normal3
        super.init(point1, point2, point3, material: material, transform: transform)
    }

    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    override func normalLocal(at point: Point, additionalData: ShapeIntersectionData? = nil) -> Vector {
        guard let data = additionalData as? TriangleIntersectionAdditionalData else {
            fatalError()
        }

        return normal2 * data.u
            + normal3 * data.v
            + normal1 * (1 - data.u - data.v)
    }
}

#if TEST
import XCTest

final class SmoothTriangleTests: XCTestCase {

    func test_intersection() {
        let triangle = SmoothTriangle(
            Point(0, 1, 0),
            Point(-1, 0, 0),
            Point(1, 0, 0),
            Vector(0, 1, 0),
            Vector(-1, 0, 0),
            Vector(1, 0, 0)
        )
        let ray = Ray(origin: Point(-0.2, 0.3, -2), direction: Vector(0, 0, 1))
        let intersections = triangle.intersectLocal(with: ray)

        guard let additionalData = intersections[0].additionalData as? TriangleIntersectionAdditionalData else {
            return XCTFail()
        }

        XCTAssertEqual(additionalData.u, 0.45, accuracy: .tolerance)
        XCTAssertEqual(additionalData.v, 0.25, accuracy: .tolerance)
    }

    func test_normal() {
        let triangle = SmoothTriangle(
            Point(0, 1, 0),
            Point(-1, 0, 0),
            Point(1, 0, 0),
            Vector(0, 1, 0),
            Vector(-1, 0, 0),
            Vector(1, 0, 0)
        )
        let normal = triangle.normal(
            at: Point(0, 0, 0),
            additionalData: TriangleIntersectionAdditionalData(u: 0.45, v: 0.25)
        )

        XCTAssertEqual(normal, Vector(-0.5547, 0.83205, 0))
    }
}
#endif
