import Foundation

final class SmoothTriangle: Triangle {

    let normal1: Tuple
    let normal2: Tuple
    let normal3: Tuple

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
        self.normal1 = normal1
        self.normal2 = normal2
        self.normal3 = normal3
        super.init(point1, point2, point3, material: material, transform: transform)
    }

    override func normalLocal(at point: Tuple, additionalData: ShapeIntersectionData? = nil) -> Tuple {
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
            .point(0, 1, 0),
            .point(-1, 0, 0),
            .point(1, 0, 0),
            .vector(0, 1, 0),
            .vector(-1, 0, 0),
            .vector(1, 0, 0)
        )
        let ray = Ray(origin: .point(-0.2, 0.3, -2), direction: .vector(0, 0, 1))
        let intersections = triangle.intersectLocal(with: ray)

        guard let additionalData = intersections[0].additionalData as? TriangleIntersectionAdditionalData else {
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
        let normal = triangle.normal(
            at: .point(0, 0, 0),
            additionalData: TriangleIntersectionAdditionalData(u: 0.45, v: 0.25)
        )

        XCTAssertEqual(normal, .vector(-0.5547, 0.83205, 0))
    }
}
#endif
