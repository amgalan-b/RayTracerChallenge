import ArgumentParser
import Babbage
import Foundation
import RayTracerKit

@main
enum Main {

    /// - Note: swift-argument-parser 1.0.2 yet not support async run method.
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

    @Argument(help: ArgumentHelp("OBJ file or YAML scene location. Use - to read from stdin.", valueName: "input"))
    var inputFileLocation: String

    @Option(name: .customLong("type"), help: "Input file type.")
    var inputFileType: InputType = .obj

    @Option(name: [.short, .customLong("output")], help: "Output PPM file location. Prints to stdout by default.")
    var outputFileLocation: String?

    @Option(name: .long, help: "Image width.")
    var width: Int?

    @Option(name: .long, help: "Image height.")
    var height: Int?

    private var _startTime = CFAbsoluteTimeGetCurrent()

    mutating func runAsync() async throws {
        let sceneDescription = try _readSceneDescription()
        let parser = YAMLParser()
        let (presetCamera, world) = try parser.parse(sceneDescription)
        let camera = Camera(
            width: width ?? presetCamera.width,
            height: height ?? presetCamera.height,
            fieldOfView: presetCamera.fieldOfView,
            transform: presetCamera.transform
        )

        if case .obj = inputFileType {
            let objParser = Parser()
            let objContent = try inputFileLocation._readFileOrStandardInput()
            let object = objParser.parse(objContent, isBoundingVolumeHierarchyEnabled: true)
            world.objects.append(object)
        }

        let ppm = await camera.renderParallel(world: world)
            .ppm()

        _write(content: ppm)
        _printTimeElapsed()
    }

    private func _readSceneDescription() throws -> String {
        switch inputFileType {
        case .scene:
            return try inputFileLocation._readFileOrStandardInput()
        case .obj:
            let objBackgroundSceneLocation = Bundle.module.url(
                forResource: "background",
                withExtension: "yaml",
                subdirectory: "Scenes"
            )!

            return try String(contentsOf: objBackgroundSceneLocation)
        }
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

enum InputType: String, ExpressibleByArgument {

    case obj
    case scene

    init?(argument: String) {
        self.init(rawValue: argument)
    }
}

extension String {

    fileprivate func _readFileOrStandardInput() throws -> String {
        guard self == "-" else {
            return try String(contentsOfFile: self)
        }

        var result = ""
        while let line = readLine(strippingNewline: false) {
            result.append(line)
        }

        return result
    }
}
