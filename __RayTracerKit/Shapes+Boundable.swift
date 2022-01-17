import Foundation

extension Sphere: BoundableShape {

    func boundingBox() -> BoundingBox {
        return BoundingBox(minimum: .point(-1, -1, -1), maximum: .point(1, 1, 1))
    }
}

extension Cube: BoundableShape {

    func boundingBox() -> BoundingBox {
        return BoundingBox(minimum: .point(-1, -1, -1), maximum: .point(1, 1, 1))
    }
}

extension Cylinder: BoundableShape {

    func boundingBox() -> BoundingBox {
        return BoundingBox(minimum: .point(-1, minimum, -1), maximum: .point(1, maximum, 1))
    }
}

extension Cone: BoundableShape {

    func boundingBox() -> BoundingBox {
        let a = minimum.absoluteValue
        let b = maximum.absoluteValue
        let limit = max(a, b)

        return BoundingBox(minimum: .point(-limit, minimum, -limit), maximum: .point(limit, maximum, limit))
    }
}

extension Triangle: BoundableShape {

    func boundingBox() -> BoundingBox {
        var box = BoundingBox()
        box.addPoint(point1)
        box.addPoint(point2)
        box.addPoint(point3)

        return box
    }
}

#if TEST
import XCTest

extension BoundingBoxTests {

    func test_boundingBox_sphere() {
        let sphere = Sphere()
        let box = sphere.boundingBox()

        XCTAssertEqual(box.minimum, .point(-1, -1, -1))
        XCTAssertEqual(box.maximum, .point(1, 1, 1))
    }

    func test_boundingBox_cube() {
        let cube = Cube()
        let box = cube.boundingBox()

        XCTAssertEqual(box.minimum, .point(-1, -1, -1))
        XCTAssertEqual(box.maximum, .point(1, 1, 1))
    }

    func test_boundingBox_cylinder() {
        let c1 = Cylinder()
        let b1 = c1.boundingBox()

        let c2 = Cylinder(minimum: -5, maximum: 3)
        let b2 = c2.boundingBox()

        XCTAssertEqual(b1.minimum, .point(-1, -.greatestFiniteMagnitude, -1))
        XCTAssertEqual(b1.maximum, .point(1, .greatestFiniteMagnitude, 1))

        XCTAssertEqual(b2.minimum, .point(-1, -5, -1))
        XCTAssertEqual(b2.maximum, .point(1, 3, 1))
    }

    func test_boundingBox_cone() {
        let cone = Cone(minimum: -5, maximum: 3)
        let box = cone.boundingBox()

        XCTAssertEqual(box.minimum, .point(-5, -5, -5))
        XCTAssertEqual(box.maximum, .point(5, 3, 5))
    }

    func test_boundingBox_triangle() {
        let triangle = Triangle(.point(-3, 7, 2), .point(6, 2, -4), .point(2, -1, -1))
        let box = triangle.boundingBox()

        XCTAssertEqual(box.minimum, .point(-3, -1, -4))
        XCTAssertEqual(box.maximum, .point(6, 7, 2))
    }
}
#endif
