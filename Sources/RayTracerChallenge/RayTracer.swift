import ArgumentParser
import Babbage
import Foundation
import RayTracerKit

@main
enum Main {

    static func main() async throws {
        var command = RayTracer.parseOrExit()
        do {
            try await command.runAsync()
        } catch {
            RayTracer.exit(withError: error)
        }
    }
}

struct RayTracer: ParsableCommand {

    @Argument(help: ArgumentHelp("OBJ file location. Use - to read from stdin.", valueName: "input"))
    var inputFileLocation: String

    @Option(name: [.short, .customLong("output")], help: "Output PPM file location.")
    var outputFileLocation: String?

    @Option(name: .long, help: "Image width.")
    var width: Int = 800

    @Option(name: .long, help: "Image height.")
    var height: Int = 800

    @Flag(name: .shortAndLong, help: "Show debug messages.")
    var debug = false

    private var _startTime = CFAbsoluteTimeGetCurrent()

    mutating func runAsync() async throws {
        let input = try _readInput()
        let world = try _makeWorld(content: input)
        let camera = Camera(
            width: width,
            height: height,
            fieldOfView: .pi / 3,
            transform: .viewTransform(
                origin: .point(0, 4, -7),
                target: .point(0, 1, 0),
                orientation: .vector(0, 1, 0)
            )
        )

        let ppm = await camera.renderParallel(world: world)
            .ppm()

        _write(content: ppm)
        _printTimeElapsed()
    }

    private func _readInput() throws -> String {
        if inputFileLocation == "-" {
            var result = ""
            while let line = readLine(strippingNewline: false) {
                result.append(line)
            }

            return result
        }

        let url = URL(fileURLWithPath: inputFileLocation)
        return try String(contentsOf: url)
    }

    private func _makeWorld(content: String) throws -> World {
        let parser = Parser()
        let object = parser.parse(content, isBoundingVolumeHierarchyEnabled: true)

        return World(
            objects: [object],
            light: .pointLight(at: .point(0, 10, -10), intensity: .white)
        )
    }

    fileprivate func _write(content: String) {
        guard let fileLocation = outputFileLocation else {
            print(content)
            return
        }

        let url = URL(fileURLWithPath: fileLocation)
        try! content.write(to: url, atomically: true, encoding: .utf8)
    }

    private func _printTimeElapsed() {
        let diff = CFAbsoluteTimeGetCurrent() - _startTime
        let formatted = String(format: "%.3f seconds", diff)
        print(formatted, to: &standardError)
    }
}
