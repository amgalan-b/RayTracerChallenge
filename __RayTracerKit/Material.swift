import Foundation

struct Material {

    var color: Color
    var ambient: Double
    var diffuse: Double
    var specular: Double
    var shininess: Double

    init(color: Color, ambient: Double, diffuse: Double, specular: Double, shininess: Double) {
        self.color = color
        self.ambient = ambient
        self.diffuse = diffuse
        self.specular = specular
        self.shininess = shininess
    }
}

extension Material {

    static let `default` = Material(color: .white, ambient: 0.1, diffuse: 0.9, specular: 0.9, shininess: 200)
}

#if TEST
import XCTest

final class MaterialTests: XCTestCase {
}
#endif
