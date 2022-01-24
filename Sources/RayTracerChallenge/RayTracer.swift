import RayTracerKit
import Foundation

@main
enum RayTracer {

    static func main() async {
        let start = CFAbsoluteTimeGetCurrent()

        let world = _makeWorld()
        let camera = Camera(
            width: 1600,
            height: 1600,
            fieldOfView: .pi / 3,
            transform: .viewTransform(
                origin: .point(0, 4, -7),
                target: .point(0, 1, 0),
                orientation: .vector(0, 1, 0)
            )
        )

        await camera.renderParallel(world: world)
            .ppm()
            ._write()

        let diff = CFAbsoluteTimeGetCurrent() - start
        let output = String(format: "%.3f seconds", diff)
        print(output)
    }

    private static func _makeWorld() -> World {
        let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("teapot-2.txt")
        let input = try! String(contentsOf: url)
        let parser = Parser()
        let object = parser.parse(input, isBoundingVolumeHierarchyEnabled: true)!

        let world = World(
            objects: [object],
            light: .pointLight(at: .point(0, 10, -10), intensity: .white)
        )

        return world
    }
}

extension String {

    fileprivate func _write() {
        let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("output.ppm")

        try! write(to: url, atomically: true, encoding: .utf8)
    }
}
