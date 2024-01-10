import Foundation
import Yams

extension YAMLParser {

    /// - Note: Definitions are replaced by their actual value. Returns YAML string.
    func expandDefinitions(_ content: String) throws -> String {
        func __expand(_ any: Any) -> Any {
            switch any {
            case let string as String:
                for (key, value) in definitions where key == string {
                    return value
                }
                return any
            default:
                return any
            }
        }

        guard let commands = try Yams.load(yaml: content) as? [[String: Any]] else {
            fatalError()
        }

        var definitions = [String: Any]()
        var result = [Any]()

        for var command in commands {
            guard let label = command["define"] as? String else {
                command._forEachLeafNode(body: __expand(_:))
                result.append(command)
                continue
            }

            if var array = command["value"] as? [Any] {
                array._forEachLeafNode(body: __expand(_:))
                definitions[label] = array
                continue
            }

            guard let value = command["value"] as? [String: Any] else {
                fatalError()
            }

            guard let extendLabel = command["extend"] as? String else {
                definitions[label] = value
                continue
            }

            let definition = definitions[extendLabel] as! [String: Any]
            definitions[label] = definition.merging(value) { $1 }
        }

        return try Yams.dump(object: result)
    }
}

extension Dictionary where Key == String, Value == Any {

    fileprivate mutating func _forEachLeafNode(body: (Any) -> Any) {
        for (key, value) in self {
            switch value {
            case var dictionary as [String: Any]:
                dictionary._forEachLeafNode(body: body)
                self[key] = dictionary
            case var array as [Any]:
                array._forEachLeafNode(body: body)
                self[key] = array
            default:
                let expanded = body(value)
                guard key == "add", let replacedValue = expanded as? [String: Any] else {
                    self[key] = expanded
                    continue
                }

                self = filter { $0.key != key }
                    .merging(replacedValue) { $1 }
            }
        }
    }
}

extension Array where Element == Any {

    fileprivate mutating func _forEachLeafNode(body: (Any) -> Any) {
        for index in indices {
            switch self[index] {
            case var dictionary as [String: Any]:
                dictionary._forEachLeafNode(body: body)
                self[index] = dictionary
            case var array as [Any]:
                array._forEachLeafNode(body: body)
                self[index] = array
            default:
                let result = body(self[index])
                if let array = result as? [Any] {
                    self.remove(at: index)
                    self.insert(contentsOf: array, at: index)
                } else {
                    self[index] = result
                }
            }
        }
    }
}

#if TEST
import XCTest

extension YAMLParserTests {

    func test_expandDefinitions() throws {
        let content = """
        - define: white-material
          value:
            color: [1, 1, 1]
            diffuse: 0.7
            ambient: 0.1
            specular: 0.0
            reflective: 0.1
        - add: cube
          material: white-material
          transform:
            - [translate, 4, 0, 0]
        """

        let parser = YAMLParser()
        let result = try parser.expandDefinitions(content)
        let decoder = YAMLDecoder()
        let commands = try decoder.decode([Command].self, from: result)

        guard case let .shape(cube) = commands[0] else {
            return XCTFail()
        }

        XCTAssertEqual(cube.material, .default(color: .white, ambient: 0.1, diffuse: 0.7, specular: 0, reflective: 0.1))
        XCTAssertEqual(cube.transform, .translation(4, 0, 0))
    }

    func test_expandDefinitions_mergeArray() throws {
        let content = """
        - define: medium-object
          value:
            - [translate, 1, -1, 1]
            - [scale, 3, 3, 3]
        - add: cube
          material:
            color: [1, 0.5, 0]
          transform:
            - medium-object
            - [translate, 4, 0, 0]
        """

        let parser = YAMLParser()
        let result = try parser.expandDefinitions(content)
        let decoder = YAMLDecoder()
        let commands = try decoder.decode([Command].self, from: result)

        guard case let .shape(cube) = commands[0] else {
            return XCTFail()
        }

        XCTAssertEqual(cube.material, .default(color: .rgb(1, 0.5, 0)))
        XCTAssertEqual(cube.transform, .translation(4, 0, 0) * .scaling(3, 3, 3) * .translation(1, -1, 1))
    }

    func test_expandDefinitions_extend() throws {
        let content = """
        - define: white-material
          value:
            color: [1, 1, 1]
            diffuse: 0.7
            ambient: 0.1
            specular: 0.0
            reflective: 0.1
        - define: blue-material
          extend: white-material
          value:
            color: [0.537, 0.831, 0.914]
        - add: cube
          material: blue-material
          transform:
            - [translate, 4, 0, 0]
        """

        let parser = YAMLParser()
        let result = try parser.expandDefinitions(content)
        let decoder = YAMLDecoder()
        let commands = try decoder.decode([Command].self, from: result)

        guard case let .shape(cube) = commands[0] else {
            return XCTFail()
        }

        XCTAssertEqual(
            cube.material,
            .default(color: .rgb(0.537, 0.831, 0.914), ambient: 0.1, diffuse: 0.7, specular: 0, reflective: 0.1)
        )
        XCTAssertEqual(cube.transform, .translation(4, 0, 0))
    }

    func test_expandDefinitions_values() throws {
        let content = """
        - define: standard-transform
          value:
            - [translate, 1, -1, 1]
        - define: medium-object
          value:
            - standard-transform
            - [scale, 3, 3, 3]
        - add: cube
          material:
            color: [1, 0.5, 0]
          transform:
            - medium-object
            - [translate, 4, 0, 0]
        """

        let parser = YAMLParser()
        let result = try parser.expandDefinitions(content)
        let decoder = YAMLDecoder()
        let commands = try decoder.decode([Command].self, from: result)

        guard case let .shape(cube) = commands[0] else {
            return XCTFail()
        }

        XCTAssertEqual(cube.material, .default(color: .rgb(1, 0.5, 0)))
        XCTAssertEqual(cube.transform, .translation(4, 0, 0) * .scaling(3, 3, 3) * .translation(1, -1, 1))
    }

    func test_expand_add() throws {
        let content = """
        - define: MappedCube
          value:
            add: cube
            material:
              color: [1, 1, 1]
        - add: MappedCube
          transform:
            - [translate, 0, 1, 0]
            - [rotate-y, 0.7854]
        - add: MappedCube
          transform:
            - [translate, 0, 2, 0]
        """

        let parser = YAMLParser()
        let result = try parser.expandDefinitions(content)
        let decoder = YAMLDecoder()
        let commands = try decoder.decode([Command].self, from: result)

        guard case let .shape(r1) = commands[0], case let .shape(r2) = commands[1] else {
            return XCTFail()
        }

        XCTAssertEqual(r1.material, .default(color: .white))
        XCTAssertEqual(r1.transform, .rotationY(0.7854) * .translation(0, 1, 0))
        XCTAssertEqual(r2.material, .default(color: .white))
        XCTAssertEqual(r2.transform, .translation(0, 2, 0))
    }
}
#endif
