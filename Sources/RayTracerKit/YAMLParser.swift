import Foundation
import Yams

public final class YAMLParser {

    public init() {
    }

    public func parse(_ content: String) throws -> (Camera, World) {
        let content = try expandDefinitions(content)
        let decoder = YAMLDecoder()
        let commands = try decoder.decode([Command].self, from: content)

        var camera: Camera?
        let world = World()

        for command in commands {
            switch command {
            case let .camera(c):
                camera = c
            case let .light(light):
                world.light = world.light ?? light
            case let .shape(shape):
                world.addObject(shape)
            }
        }

        return (camera!, world)
    }
}

enum Command {

    case camera(Camera)
    case light(Light)
    case shape(Shape)
}

extension Command: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        guard let addType = try container.decodeIfPresent(String.self, forKey: .add) else {
            fatalError()
        }

        switch addType {
        case "camera":
            self = .camera(try Camera(from: decoder))
        case "light":
            self = .light(try Light(from: decoder))
        case "plane":
            self = .shape(try Plane(from: decoder))
        case "cube":
            self = .shape(try Cube(from: decoder))
        case "sphere":
            self = .shape(try Sphere(from: decoder))
        case "cylinder":
            self = .shape(try Cylinder(from: decoder))
        case "cone":
            self = .shape(try Cone(from: decoder))
        default:
            fatalError()
        }
    }

    private enum _CodingKeys: String, CodingKey {

        case add
    }
}

#if TEST
import XCTest

final class YAMLParserTests: XCTestCase {

    func test_decode() throws {
        let content = """
        - add: camera
          width: 400
          height: 300
          field-of-view: 1.047
          from: [0, 1.5, -5]
          to: [0, 1, 0]
          up: [0, 1, 0]
        - add: light
          at: [-10, 10, -10]
          intensity: [1, 1, 1]
        """

        let decoder = YAMLDecoder()
        let commands = try decoder.decode([Command].self, from: content)
        let camera = Camera(
            width: 400,
            height: 300,
            fieldOfView: 1.047,
            transform: .viewTransform(
                origin: Point(0, 1.5, -5),
                target: Point(0, 1, 0),
                orientation: Vector(0, 1, 0)
            )
        )
        let light = Light.pointLight(at: Point(-10, 10, -10), intensity: .white)

        XCTAssertEqual(commands, [.camera(camera), .light(light)])
    }
}

extension Command: Equatable {
}
#endif
