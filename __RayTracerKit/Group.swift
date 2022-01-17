import Foundation

public final class Group: Shape {

    private var _children = Set<Shape>()

    var children: Set<Shape> {
        return _children
    }

    override func intersectLocal(with ray: Ray) -> [Intersection] {
        return children.reduce(into: []) { $0 += $1.intersect(with: ray) }
            .sorted(by: \.time)
    }

    override func normalLocal(at point: Tuple) -> Tuple {
        return .vector(0, 0, 0)
    }

    func addChild(_ child: Shape) {
        guard child.parent == nil else {
            fatalError()
        }

        guard !_children.contains(child) else {
            fatalError()
        }

        child.parent = self
        _children.insert(child)
    }

    func addChildren(_ children: [Shape]) {
        for child in children {
            addChild(child)
        }
    }
}

#if TEST
import XCTest

final class GroupTests: XCTestCase {

    func test_addChild() {
        let cube = Cube()
        let group = Group()
        group.addChild(cube)

        XCTAssert(group.children.contains(cube))
        XCTAssertEqual(cube.parent, group)
    }

    func test_intersect_empty() {
        let group = Group()
        let ray = Ray(origin: .point(0, 0, 0), direction: .vector(0, 0, 1))

        XCTAssertEqual(group.intersectLocal(with: ray), [])
    }

    func test_intersect() {
        let s1 = Sphere()
        let s2 = Sphere(transform: .translation(0, 0, -3))
        let s3 = Sphere(transform: .translation(5, 0, 0))

        let group = Group()
        group.addChild(s1)
        group.addChild(s2)
        group.addChild(s3)

        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let objects = group.intersectLocal(with: ray)
            .map { $0.object }

        XCTAssertEqual(objects, [s2, s2, s1, s1])
    }

    func test_intersect_transformed() {
        let sphere = Sphere(transform: .translation(5, 0, 0))
        let group = Group(transform: .scaling(2, 2, 2))
        group.addChild(sphere)

        let ray = Ray(origin: .point(10, 0, -10), direction: .vector(0, 0, 1))
        let intersections = group.intersect(with: ray)

        XCTAssertEqual(intersections.count, 2)
    }
}
#endif
