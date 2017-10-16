public protocol StoreState: Equatable, CustomLogDescriptionConvertible {}
public protocol ViewState: StoreState {}

public extension Equatable where Self: StoreState {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return false
    }
}
