public func += <T, U: StatefulView>(left: ViewModel<T>, right: U) where U.State == T {
    left.subscribe(from: right)
}

public func -= <T, U: StatefulView>(left: ViewModel<T>, right: U) where U.State == T {
    left.unsubscribe(from: right)
}

