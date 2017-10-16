public protocol CustomLogDescriptionConvertible {
    var logDescription: String { get }
}

public extension CustomLogDescriptionConvertible {
    var logDescription: String {
        return String(describing: self)
    }
}
