import Foundation

enum Texture {

    case checker(CheckerTexture)
    case alignChecker(AlignCheckerTexture)

    private var _texture: TextureProtocol {
        switch self {
        case let .checker(texture):
            return texture
        case let .alignChecker(texture):
            return texture
        }
    }

    func color(at point: Point2D) -> Color {
        return _texture.color(at: point)
    }
}

protocol TextureProtocol {

    func color(at point: Point2D) -> Color
}
