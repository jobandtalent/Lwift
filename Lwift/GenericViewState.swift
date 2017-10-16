public enum GenericViewState<D, E: Error>: ViewState {
    case loading(D?)
    case loaded(D)
    case emptyCase
    case error(E, D?)
}

// Because sometimes we simply want to render that there's been an error, without further details...
// FIXME: Change name
public enum GenericViewState2<D>: ViewState {
    case loading(D?)
    case loaded(D)
    case emptyCase
    case error(D?)
}

public extension GenericState {
    func map<V, R>(dataTransform: (D) -> V, errorTransform: (E) -> R, isEmpty: (V) -> Bool) -> GenericViewState<V, R> {
        switch self {
        case .idle:
            return GenericViewState<V, R>.loading(nil)
        case .loading(let data):
            return GenericViewState<V, R>.loading(data.map(dataTransform))
        case .loaded(let data):
            let viewData = dataTransform(data)
            return isEmpty(viewData) ? GenericViewState<V, R>.emptyCase : GenericViewState<V, R>.loaded(viewData)
        case .error(let error, let data):
            return GenericViewState<V, R>.error(errorTransform(error), data.map(dataTransform))
        }
    }

    func map<V>(dataTransform: (D) -> V, isEmpty: (V) -> Bool) -> GenericViewState2<V> {
        switch self {
        case .idle:
            return GenericViewState2<V>.loading(nil)
        case .loading(let data):
            return GenericViewState2<V>.loading(data.map(dataTransform))
        case .loaded(let data):
            let viewData = dataTransform(data)
            return isEmpty(viewData) ? GenericViewState2<V>.emptyCase : GenericViewState2<V>.loaded(viewData)
        case .error(_, let data):
            return GenericViewState2<V>.error(data.map(dataTransform))
        }
    }
}
