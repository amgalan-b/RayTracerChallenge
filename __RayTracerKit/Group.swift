import Foundation

public final class Group: Shape {

    private var _children = Set<Shape>()

    init(children: Set<Shape> = Set<Shape>(), transform: Matrix = .identity) {
        _children = children
        super.init(material: .default, transform: transform)

        for child in children {
            child.parent = self
        }
    }

    var children: Set<Shape> {
        return _children
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(_children)
    }

    override func intersectLocal(with ray: Ray) -> [Intersection] {
        guard boundingBoxLocal().isIntersected(by: ray) else {
            return []
        }

        return children.reduce(into: []) { $0 += $1.intersect(with: ray) }
            .sorted(by: \.time)
    }

    override func normalLocal(at point: Tuple) -> Tuple {
        return .vector(0, 0, 0)
    }

    override func boundingBoxLocal() -> BoundingBox {
        var box = BoundingBox()

        for child in children {
            let childBox = child.boundingBox()
            box = box.merge(with: childBox)
        }

        return box
    }

    override func isEqual(to shape: Shape) -> Bool {
        guard let group = shape as? Group else {
            return false
        }

        return children == group.children
    }

    override func constructBoundingVolumeHierarchy(threshold: Int) {
        if threshold <= children.count {
            let (left, right) = partition()
            if !left.children.isEmpty {
                addChild(left)
            }
            if !right.children.isEmpty {
                addChild(right)
            }
        }

        for child in children {
            child.constructBoundingVolumeHierarchy(threshold: threshold)
        }
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

    func removeChild(_ child: Shape) {
        guard child.parent == self else {
            fatalError()
        }

        guard _children.contains(child) else {
            fatalError()
        }

        child.parent = nil
        _children.remove(child)
    }

    func addChildren(_ children: [Shape]) {
        for child in children {
            addChild(child)
        }
    }

    func partition() -> (Group, Group) {
        let (leftBox, rightBox) = boundingBoxLocal().split()
        let leftGroup = Group()
        let rightGroup = Group()

        for child in children {
            let childBox = child.boundingBox()
            if leftBox.contains(childBox) {
                removeChild(child)
                leftGroup.addChild(child)
            }

            if rightBox.contains(childBox) {
                removeChild(child)
                rightGroup.addChild(child)
            }
        }

        return (leftGroup, rightGroup)
    }
}

#if TEST
import XCTest

final class GroupTests: XCTestCase {

    func test_addChild() {
        let cube = Cube()
        let group = Group(children: [cube])

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
        let group = Group(children: [s1, s2, s3])

        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let objects = group.intersectLocal(with: ray)
            .map { $0.object }

        XCTAssertEqual(objects, [s2, s2, s1, s1])
    }

    func test_intersect_transformed() {
        let sphere = Sphere(transform: .translation(5, 0, 0))
        let group = Group(children: [sphere], transform: .scaling(2, 2, 2))

        let ray = Ray(origin: .point(10, 0, -10), direction: .vector(0, 0, 1))
        let intersections = group.intersect(with: ray)

        XCTAssertEqual(intersections.count, 2)
    }

    func test_boundingBox() {
        let sphere = Sphere(transform: .translation(2, 5, -3) * .scaling(2, 2, 2))
        let cylinder = Cylinder(transform: .translation(-4, -1, 4) * .scaling(0.5, 1, 0.5), minimum: -2, maximum: 2)
        let group = Group(children: [sphere, cylinder])
        let box = group.boundingBoxLocal()

        XCTAssertEqual(box.minimum, .point(-4.5, -3, -5))
        XCTAssertEqual(box.maximum, .point(4, 7, 4.5))
    }

    func test_partition() {
        let s1 = Sphere(transform: .translation(-2, 0, 0))
        let s2 = Sphere(transform: .translation(2, 0, 0))
        let s3 = Sphere()
        let group = Group(children: [s1, s2, s3])
        let (left, right) = group.partition()

        XCTAssertEqual(group.children, [s3])
        XCTAssertEqual(left.children, [s1])
        XCTAssertEqual(right.children, [s2])
    }

    func test_constructBVH() {
        let s1 = Sphere(transform: .translation(-2, -2, 0))
        let s2 = Sphere(transform: .translation(-2, 2, 0))
        let s3 = Sphere(transform: .scaling(4, 4, 4))

        let group = Group(children: [s1, s2, s3])
        group.constructBoundingVolumeHierarchy(threshold: 1)

        let expected = Group(children: [
            s3,
            Group(children: [
                Group(children: [s1]),
                Group(children: [s2]),
            ]),
        ])

        XCTAssertEqual(group, expected)
    }

    func test_constructBVH_threshold() {
        let s1 = Sphere(transform: .translation(-2, 0, 0))
        let s2 = Sphere(transform: .translation(2, 1, 0))
        let s3 = Sphere(transform: .translation(2, -1, 0))
        let s4 = Sphere()

        let group = Group(children: [s4, Group(children: [s1, s2, s3])])
        group.constructBoundingVolumeHierarchy(threshold: 3)

        let expected = Group(children: [
            s4,
            Group(children: [
                Group(children: [s1]),
                Group(children: [s2, s3]),
            ]),
        ])

        XCTAssertEqual(group, expected)
    }
}
#endif
