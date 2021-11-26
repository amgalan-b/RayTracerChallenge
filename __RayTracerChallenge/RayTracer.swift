import __RayTracerKit

@main
enum RayTracer {

    static func main() async {
        let start = CFAbsoluteTimeGetCurrent()

        let world = _makeWorld()
        let camera = Camera(
            width: 800,
            height: 800,
            fieldOfView: .pi / 3,
            transform: .viewTransform(
                origin: .point(0, 1.5, -5),
                direction: .point(0, 1, 0),
                orientation: .vector(0, 1, 0)
            )
        )

        camera.render(world: world)
            .ppm()
            ._write()

        let diff = CFAbsoluteTimeGetCurrent() - start
        let output = String(format: "%.3f seconds", diff)
        print(output)
    }

    private static func _makeWorld() -> World {
        let floor = Sphere()
        floor.transform = .scaling(10, 0.01, 10)

        let middle = Sphere()
        middle.transform = .translation(-0.5, 1, 0.5)

        let world = World(objects: [middle, floor], light: .pointLight(at: .point(-10, 10, -10), intensity: .white))

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
