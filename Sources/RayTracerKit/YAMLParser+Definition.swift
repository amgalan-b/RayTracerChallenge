import Babbage
import Foundation
import Yams

extension YAMLParser {

    /// - Note: Definitions are replaced by their actual value. Returns YAML string.
    func expandDefinitions(_ content: String) throws -> String {
        guard let commands = try Yams.load(yaml: content) as? [[String: Any]] else {
            fatalError()
        }

        var definitions = [String: Any]()
        var result = [Any]()

        #warning("refactor this")
        for var command in commands {
            if let label = command["define"] as? String {
                let value = command["value"]
                guard let extendLabel = command["extend"] as? String else {
                    switch value {
                    case var array as [Any]:
                        array.traverse {
                            switch $0 {
                            case let string as String:
                                for (key, value) in definitions where key == string {
                                    return value
                                }
                                return $0
                            default:
                                return $0
                            }
                        }
                        definitions[label] = array
                    default:
                        definitions[label] = value
                    }
                    continue
                }

                var definition = definitions[extendLabel] as! [String: Any]
                definition.merge(value as! [String: Any]) { $1 }

                definitions[label] = definition
                continue
            }

            command.traverse {
                switch $0 {
                case let string as String:
                    for (key, value) in definitions where key == string {
                        return value
                    }
                    return $0
                default:
                    return $0
                }
            }
            result.append(command)
        }

        return try Yams.dump(object: result)
    }
}

extension Dictionary where Key == String, Value == Any {

    mutating func traverse(body: (Any) -> Any) {
        for (key, value) in self {
            switch value {
            case var dictionary as [String: Any]:
                dictionary.traverse(body: body)
                self[key] = dictionary
            case var array as [Any]:
                array.traverse(body: body)
                self[key] = array
            default:
                self[key] = body(value)
            }
        }
    }
}

extension Array where Element == Any {

    mutating func traverse(body: (Any) -> Any) {
        for index in indices {
            switch self[index] {
            case var dictionary as [String: Any]:
                dictionary.traverse(body: body)
                self[index] = dictionary
            case var array as [Any]:
                array.traverse(body: body)
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

        guard case let .cube(cube) = commands[0] else {
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

        guard case let .cube(cube) = commands[0] else {
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

        guard case let .cube(cube) = commands[0] else {
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
            - [scale, 0.5, 0.5, 0.5]
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
        print(result)
        let decoder = YAMLDecoder()
        let commands = try decoder.decode([Command].self, from: result)

        guard case let .cube(cube) = commands[0] else {
            return XCTFail()
        }

        XCTAssertEqual(cube.material, .default(color: .rgb(1, 0.5, 0)))
        XCTAssertEqual(
            cube.transform,
            .translation(4, 0, 0) * .scaling(3, 3, 3) * .scaling(0.5, 0.5, 0.5) * .translation(1, -1, 1)
        )
    }
}
#endif
