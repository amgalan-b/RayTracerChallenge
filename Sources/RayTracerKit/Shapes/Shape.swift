import Foundation

public class Shape: Equatable, Hashable, Decodable {

    var material: Material
    var transform: Matrix
    var isShadowCasting: Bool

    var parent: Group?

    init(material: Material = .default, transform: Matrix = .identity, isShadowCasting: Bool = true) {
        self.material = material
        self.transform = transform
        self.isShadowCasting = isShadowCasting
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        self.material = try container.decodeIfPresent(Material.self, forKey: .material) ?? .default
        self.transform = try container.decodeIfPresent([Matrix].self, forKey: .transform)?
            .reversed()
            .reduce1(*) ?? .identity
        self.isShadowCasting = try container.decodeIfPresent(Bool.self, forKey: .shadow) ?? true
    }

    /// - Note: Not declared in an extension, so it can be overridden by a subclass.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    final func intersect(with ray: Ray) -> [Intersection] {
        let localRay = ray.transformed(with: transform.inversed())
        return intersectLocal(with: localRay)
    }

    final func normal(at worldPoint: Point, additionalData: ShapeIntersectionData? = nil) -> Vector {
        let objectPoint = _convertWorldToObjectSpace(point: worldPoint)
        let objectNormal = normalLocal(at: objectPoint, additionalData: additionalData)

        return _convertObjectToWorldSpace(normal: objectNormal)
    }

    final func boundingBox() -> BoundingBox {
        return boundingBoxLocal().transformed(transform)
    }

    /// - Note: Need to be overridden by composite shapes.
    func constructBoundingVolumeHierarchy(threshold: Int) {
    }

    /// - Note: Shapes contain themselves.
    func includes(_ shape: Shape) -> Bool {
        return self == shape
    }

    func intersectLocal(with ray: Ray) -> [Intersection] {
        fatalError()
    }

    func normalLocal(at point: Point, additionalData: ShapeIntersectionData? = nil) -> Vector {
        fatalError()
    }

    func boundingBoxLocal() -> BoundingBox {
        fatalError()
    }

    /// - Note: Composite shapes should override with their own implementation.
    func isEqual(to shape: Shape) -> Bool {
        return self === shape
    }

    fileprivate func _convertWorldToObjectSpace(point worldPoint: Point) -> Point {
        guard let parent = parent else {
            return transform.inversed() * worldPoint
        }

        return transform.inversed() * parent._convertWorldToObjectSpace(point: worldPoint)
    }

    fileprivate func _convertObjectToWorldSpace(normal objectNormal: Vector) -> Vector {
        let adjusted = transform.inversed().transposed() * objectNormal
        let normal = Vector(adjusted.x, adjusted.y, adjusted.z)
            .normalized()

        guard let parent = parent else {
            return normal
        }

        return parent._convertObjectToWorldSpace(normal: normal)
    }
}

extension Shape {

    public static func == (lhs: Shape, rhs: Shape) -> Bool {
        return lhs.isEqual(to: rhs)
    }
}

extension Shape {

    private enum _CodingKeys: String, CodingKey {

        case material
        case shadow
        case transform
    }
}

private final class _TestShape: Shape {

    fileprivate var _ray: Ray?

    override func intersectLocal(with ray: Ray) -> [Intersection] {
        _ray = ray
        return []
    }

    override func normalLocal(at point: Point, additionalData: ShapeIntersectionData? = nil) -> Vector {
        return Vector(point.x, point.y, point.z)
    }
}

#if TEST
import XCTest
import Yams

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
        let ray = Ray(origin: Point(0, 0, -5), direction: Vector(0, 0, 1))
        let shape = _TestShape(transform: .scaling(2, 2, 2))
        _ = shape.intersect(with: ray)

        XCTAssertEqual(shape._ray, Ray(origin: Point(0, 0, -2.5), direction: Vector(0, 0, 0.5)))
    }

    func test_intersect_translatedShape() {
        let ray = Ray(origin: Point(0, 0, -5), direction: Vector(0, 0, 1))
        let shape = _TestShape(transform: .translation(5, 0, 0))
        _ = shape.intersect(with: ray)

        XCTAssertEqual(shape._ray, Ray(origin: Point(-5, 0, -5), direction: Vector(0, 0, 1)))
    }

    func test_normal_translatedShape() {
        let shape = _TestShape(transform: .translation(0, 1, 0))
        let normal = shape.normal(at: Point(0, 1.70711, -0.70711))

        XCTAssertEqual(normal, Vector(0, 0.70711, -0.70711))
    }

    func test_normal_arbitraryTransform() {
        let shape = _TestShape(transform: .scaling(1, 0.5, 1) * .rotationZ(.pi / 5))
        let normal = shape.normal(at: Point(0, 0.7071, -0.7071))

        XCTAssertEqual(normal, Vector(0, 0.97014, -0.24254))
    }

    func test_normal_hasParent() {
        let g1 = Group(transform: .rotationY(.pi / 2))
        let g2 = Group(transform: .scaling(1, 2, 3))
        g1.addChild(g2)

        let sphere = Sphere(transform: .translation(5, 0, 0))
        g2.addChild(sphere)

        let result = sphere.normal(at: Point(1.7321, 1.1547, -5.5774))
        XCTAssertEqual(result, Vector(0.2857, 0.42854, -0.85716))
    }

    func test_convert_point() {
        let childGroup = Group(transform: .scaling(2, 2, 2))
        let sphere = Sphere(transform: .translation(5, 0, 0))
        childGroup.addChild(sphere)
        let parentGroup = Group(transform: .rotationY(.pi / 2))
        parentGroup.addChild(childGroup)

        let result = sphere._convertWorldToObjectSpace(point: Point(-2, 0, -10))

        XCTAssertEqual(result, Point(0, 0, -1))
    }

    func test_convert_normal() {
        let g1 = Group(transform: .rotationY(.pi / 2))
        let g2 = Group(transform: .scaling(1, 2, 3))
        g1.addChild(g2)

        let sphere = Sphere(transform: .translation(5, 0, 0))
        g2.addChild(sphere)

        let result = sphere._convertObjectToWorldSpace(normal: Vector(sqrt(3) / 3, sqrt(3) / 3, sqrt(3) / 3))
        XCTAssertEqual(result, Vector(0.28571, 0.42857, -0.85714))
    }

    func test_decode() throws {
        let content = """
        add: sphere
        material:
          color: [0.373, 0.404, 0.550]
          diffuse: 0.2
          ambient: 0.0
          specular: 1.0
          shininess: 200
          reflective: 0.7
          transparency: 0.7
          refractive_index: 1.5
        transform:
          - [translate, 4, 0, 0]
        """

        let decoder = YAMLDecoder()
        let sphere = try decoder.decode(Sphere.self, from: content)
        let material = Material.default(
            color: .rgb(0.373, 0.404, 0.550),
            ambient: 0,
            diffuse: 0.2,
            specular: 1,
            shininess: 200,
            reflective: 0.7,
            transparency: 0.7,
            refractiveIndex: 1.5
        )

        XCTAssertEqual(sphere.material, material)
        XCTAssertEqual(sphere.transform, .translation(4, 0, 0))
    }

    func test_decode_transform() throws {
        let content = """
        add: plane
        material:
          color: [1, 1, 1]
          ambient: 1
          diffuse: 0
          specular: 0
        transform:
          - [rotate-x, 1.5707963267948966] # pi/2
          - [translate, 0, 0, 500]
        """

        let decoder = YAMLDecoder()
        let plane = try decoder.decode(Plane.self, from: content)

        XCTAssertEqual(plane.material, .default(color: .white, ambient: 1, diffuse: 0, specular: 0))
        XCTAssertEqual(plane.transform, .translation(0, 0, 500) * .rotationX(.pi / 2))
    }
}

extension Shape {

    func _intersectTimes(origin: Point, direction: Vector) -> [Double] {
        return intersectLocal(with: Ray(origin: origin, direction: direction.normalized()))
            .map { $0.time }
    }
}
#endif
