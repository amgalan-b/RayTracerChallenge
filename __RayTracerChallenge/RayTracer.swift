import __RayTracerKit

@main
enum RayTracer {

    static func main() async {
        let start = CFAbsoluteTimeGetCurrent()

        await Canvas(width: 400, height: 400)
            .ppm()
            ._write()

        let diff = CFAbsoluteTimeGetCurrent() - start
        let output = String(format: "%.3f seconds", diff)
        print(output)
    }
}

extension String {

    fileprivate func _write() {
        let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("output.ppm")

        try! write(to: url, atomically: true, encoding: .utf8)
    }
}
