import Foundation

protocol FunctionalScoping {
}

extension FunctionalScoping {

    func apply(_ closure: (inout Self) -> Void) -> Self {
        var copy = self
        closure(&copy)

        return copy
    }

    func run<Type>(_ transform: (Self) -> Type) -> Type {
        return transform(self)
    }
}

extension Int: FunctionalScoping {
}

extension Double: FunctionalScoping {
}

extension Array: FunctionalScoping {
}
