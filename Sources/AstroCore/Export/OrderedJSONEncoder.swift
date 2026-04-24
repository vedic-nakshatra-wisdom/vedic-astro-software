import Foundation

// MARK: - Internal JSON Representation

/// A JSON value that preserves key insertion order for objects.
enum JSONValue {
    case object([(String, JSONValue)])
    case array([JSONValue])
    case string(String)
    case int(Int)
    case number(Double)
    case bool(Bool)
    case null
}

// MARK: - OrderedJSONEncoder

/// A JSON encoder that preserves key insertion order.
///
/// Swift's built-in `JSONEncoder` uses dictionaries internally, which means
/// JSON keys appear in arbitrary order regardless of how `encode(to:)` is
/// implemented. This encoder stores keyed container entries as ordered arrays,
/// guaranteeing that keys appear in the same order they were encoded.
///
/// Output is pretty-printed with 2-space indentation.
public final class OrderedJSONEncoder {

    private nonisolated(unsafe) static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    public init() {}

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = _OrderedEncoder(dateFormatter: Self.iso8601Formatter)
        try value.encode(to: encoder)
        guard let topLevel = encoder.value else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Top-level value did not encode any data."
                )
            )
        }
        let json = serialize(topLevel, indent: 0)
        guard let data = json.data(using: .utf8) else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to convert JSON string to UTF-8 data."
                )
            )
        }
        return data
    }

    // MARK: - Serialization

    private func serialize(_ value: JSONValue, indent: Int) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        let childIndent = String(repeating: "  ", count: indent + 1)

        switch value {
        case .object(let pairs):
            if pairs.isEmpty { return "{}" }
            var parts: [String] = []
            for (key, val) in pairs {
                let serializedKey = serializeString(key)
                let serializedVal = serialize(val, indent: indent + 1)
                parts.append("\(childIndent)\(serializedKey): \(serializedVal)")
            }
            return "{\n\(parts.joined(separator: ",\n"))\n\(indentStr)}"

        case .array(let items):
            if items.isEmpty { return "[]" }
            var parts: [String] = []
            for item in items {
                parts.append("\(childIndent)\(serialize(item, indent: indent + 1))")
            }
            return "[\n\(parts.joined(separator: ",\n"))\n\(indentStr)]"

        case .string(let s):
            return serializeString(s)

        case .int(let i):
            return "\(i)"

        case .number(let d):
            if d.isNaN { return "null" }
            if d.isInfinite { return "null" }
            // Use full precision; avoid trailing ".0" for whole numbers.
            if d == d.rounded(.towardZero) && !d.isZero && abs(d) < 1e18 {
                return "\(Int64(d))"
            }
            return "\(d)"

        case .bool(let b):
            return b ? "true" : "false"

        case .null:
            return "null"
        }
    }

    private func serializeString(_ s: String) -> String {
        var out = "\""
        for ch in s.unicodeScalars {
            switch ch {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            case "\u{08}": out += "\\b"
            case "\u{0C}": out += "\\f"
            default:
                if ch.value < 0x20 {
                    out += String(format: "\\u%04x", ch.value)
                } else {
                    out += String(ch)
                }
            }
        }
        out += "\""
        return out
    }
}

// MARK: - Internal Encoder

private final class _OrderedEncoder: Encoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any] = [:]
    let dateFormatter: ISO8601DateFormatter

    /// The encoded value. Set once a container finishes encoding.
    var value: JSONValue?

    init(codingPath: [CodingKey] = [], dateFormatter: ISO8601DateFormatter) {
        self.codingPath = codingPath
        self.dateFormatter = dateFormatter
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        let container = _OrderedKeyedContainer<Key>(
            codingPath: codingPath,
            encoder: self
        )
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        _OrderedUnkeyedContainer(codingPath: codingPath, encoder: self)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        _OrderedSingleValueContainer(codingPath: codingPath, encoder: self)
    }
}

// MARK: - Keyed Container

private final class _OrderedKeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey]
    private let encoder: _OrderedEncoder
    private var entries: [(String, JSONValue)] = []

    init(codingPath: [CodingKey], encoder: _OrderedEncoder) {
        self.codingPath = codingPath
        self.encoder = encoder
        // Initialize immediately so empty objects encode as {} not nil
        encoder.value = .object([])
    }

    private func commit() {
        encoder.value = .object(entries)
    }

    // MARK: Encode Primitives

    func encodeNil(forKey key: Key) throws {
        entries.append((key.stringValue, .null))
        commit()
    }

    func encode(_ value: Bool, forKey key: Key) throws {
        entries.append((key.stringValue, .bool(value)))
        commit()
    }

    func encode(_ value: String, forKey key: Key) throws {
        entries.append((key.stringValue, .string(value)))
        commit()
    }

    func encode(_ value: Int, forKey key: Key) throws {
        entries.append((key.stringValue, .int(value)))
        commit()
    }

    func encode(_ value: Int8, forKey key: Key) throws {
        entries.append((key.stringValue, .int(Int(value))))
        commit()
    }

    func encode(_ value: Int16, forKey key: Key) throws {
        entries.append((key.stringValue, .int(Int(value))))
        commit()
    }

    func encode(_ value: Int32, forKey key: Key) throws {
        entries.append((key.stringValue, .int(Int(value))))
        commit()
    }

    func encode(_ value: Int64, forKey key: Key) throws {
        entries.append((key.stringValue, .int(Int(value))))
        commit()
    }

    func encode(_ value: UInt, forKey key: Key) throws {
        entries.append((key.stringValue, .int(Int(value))))
        commit()
    }

    func encode(_ value: UInt8, forKey key: Key) throws {
        entries.append((key.stringValue, .int(Int(value))))
        commit()
    }

    func encode(_ value: UInt16, forKey key: Key) throws {
        entries.append((key.stringValue, .int(Int(value))))
        commit()
    }

    func encode(_ value: UInt32, forKey key: Key) throws {
        entries.append((key.stringValue, .int(Int(value))))
        commit()
    }

    func encode(_ value: UInt64, forKey key: Key) throws {
        entries.append((key.stringValue, .int(Int(value))))
        commit()
    }

    func encode(_ value: Float, forKey key: Key) throws {
        entries.append((key.stringValue, .number(Double(value))))
        commit()
    }

    func encode(_ value: Double, forKey key: Key) throws {
        entries.append((key.stringValue, .number(value)))
        commit()
    }

    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        let childEncoder = _OrderedEncoder(
            codingPath: codingPath + [key],
            dateFormatter: encoder.dateFormatter
        )
        // Special-case Date to encode as ISO 8601 string.
        if let date = value as? Date {
            childEncoder.value = .string(encoder.dateFormatter.string(from: date))
        } else {
            try value.encode(to: childEncoder)
        }
        guard let encoded = childEncoder.value else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value did not encode anything."
                )
            )
        }
        entries.append((key.stringValue, encoded))
        commit()
    }

    // MARK: Nested Containers

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        let childEncoder = _OrderedEncoder(
            codingPath: codingPath + [key],
            dateFormatter: encoder.dateFormatter
        )
        let container = _OrderedKeyedContainer<NestedKey>(
            codingPath: codingPath + [key],
            encoder: childEncoder
        )
        // We need to capture the child encoder so we can read its value later.
        // Use a deferred approach: store a placeholder and update on commit.
        let index = entries.count
        entries.append((key.stringValue, .object([])))
        commit()

        // Return a wrapper that updates our entries when the nested container is done.
        let proxy = _NestedKeyedContainerProxy(
            inner: container,
            parent: self,
            index: index,
            childEncoder: childEncoder
        )
        return KeyedEncodingContainer(proxy)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let childEncoder = _OrderedEncoder(
            codingPath: codingPath + [key],
            dateFormatter: encoder.dateFormatter
        )
        let container = _OrderedUnkeyedContainer(
            codingPath: codingPath + [key],
            encoder: childEncoder
        )
        let index = entries.count
        entries.append((key.stringValue, .array([])))
        commit()

        return _NestedUnkeyedContainerProxy(
            inner: container,
            parent: self,
            index: index,
            childEncoder: childEncoder
        )
    }

    func superEncoder() -> Encoder {
        let superKey = _JSONKey(stringValue: "super")!
        return superEncoder(forKey: Key(stringValue: superKey.stringValue)!)
    }

    func superEncoder(forKey key: Key) -> Encoder {
        let childEncoder = _OrderedEncoder(
            codingPath: codingPath + [key],
            dateFormatter: encoder.dateFormatter
        )
        let index = entries.count
        entries.append((key.stringValue, .null))
        commit()

        // Return a deferred encoder whose value will be captured.
        let proxy = _DeferredEncoder(
            wrapped: childEncoder,
            parent: self,
            index: index
        )
        return proxy
    }

    /// Update entry at a given index (used by nested containers and super encoder).
    fileprivate func updateEntry(at index: Int, value: JSONValue) {
        guard index < entries.count else { return }
        let key = entries[index].0
        entries[index] = (key, value)
        commit()
    }
}

// MARK: - Nested Container Proxies

/// Proxy that forwards calls to an inner keyed container and syncs results
/// back to the parent container.
private final class _NestedKeyedContainerProxy<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey] { inner.codingPath }
    private let inner: _OrderedKeyedContainer<Key>
    private let parent: AnyObject  // _OrderedKeyedContainer<some key>
    private let index: Int
    private let childEncoder: _OrderedEncoder

    private let syncBack: (JSONValue) -> Void

    init<ParentKey: CodingKey>(
        inner: _OrderedKeyedContainer<Key>,
        parent: _OrderedKeyedContainer<ParentKey>,
        index: Int,
        childEncoder: _OrderedEncoder
    ) {
        self.inner = inner
        self.parent = parent
        self.index = index
        self.childEncoder = childEncoder
        self.syncBack = { [weak parent] val in
            parent?.updateEntry(at: index, value: val)
        }
    }

    private func sync() {
        if let val = childEncoder.value {
            syncBack(val)
        }
    }

    func encodeNil(forKey key: Key) throws { try inner.encodeNil(forKey: key); sync() }
    func encode(_ value: Bool, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: String, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Int, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Int8, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Int16, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Int32, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Int64, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: UInt, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: UInt8, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: UInt16, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: UInt32, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: UInt64, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Float, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Double, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode<T: Encodable>(_ value: T, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        inner.nestedContainer(keyedBy: keyType, forKey: key)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        inner.nestedUnkeyedContainer(forKey: key)
    }

    func superEncoder() -> Encoder { inner.superEncoder() }
    func superEncoder(forKey key: Key) -> Encoder { inner.superEncoder(forKey: key) }
}

private final class _NestedUnkeyedContainerProxy: UnkeyedEncodingContainer {
    var codingPath: [CodingKey] { inner.codingPath }
    var count: Int { inner.count }

    private let inner: _OrderedUnkeyedContainer
    private let childEncoder: _OrderedEncoder
    private let syncBack: (JSONValue) -> Void

    init<ParentKey: CodingKey>(
        inner: _OrderedUnkeyedContainer,
        parent: _OrderedKeyedContainer<ParentKey>,
        index: Int,
        childEncoder: _OrderedEncoder
    ) {
        self.inner = inner
        self.childEncoder = childEncoder
        self.syncBack = { [weak parent] val in
            parent?.updateEntry(at: index, value: val)
        }
    }

    private func sync() {
        if let val = childEncoder.value {
            syncBack(val)
        }
    }

    func encodeNil() throws { try inner.encodeNil(); sync() }
    func encode(_ value: Bool) throws { try inner.encode(value); sync() }
    func encode(_ value: String) throws { try inner.encode(value); sync() }
    func encode(_ value: Int) throws { try inner.encode(value); sync() }
    func encode(_ value: Int8) throws { try inner.encode(value); sync() }
    func encode(_ value: Int16) throws { try inner.encode(value); sync() }
    func encode(_ value: Int32) throws { try inner.encode(value); sync() }
    func encode(_ value: Int64) throws { try inner.encode(value); sync() }
    func encode(_ value: UInt) throws { try inner.encode(value); sync() }
    func encode(_ value: UInt8) throws { try inner.encode(value); sync() }
    func encode(_ value: UInt16) throws { try inner.encode(value); sync() }
    func encode(_ value: UInt32) throws { try inner.encode(value); sync() }
    func encode(_ value: UInt64) throws { try inner.encode(value); sync() }
    func encode(_ value: Float) throws { try inner.encode(value); sync() }
    func encode(_ value: Double) throws { try inner.encode(value); sync() }
    func encode<T: Encodable>(_ value: T) throws { try inner.encode(value); sync() }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> {
        inner.nestedContainer(keyedBy: keyType)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        inner.nestedUnkeyedContainer()
    }

    func superEncoder() -> Encoder { inner.superEncoder() }
}

/// An encoder that defers writing its value back to the parent keyed container.
private final class _DeferredEncoder: Encoder {
    var codingPath: [CodingKey] { wrapped.codingPath }
    var userInfo: [CodingUserInfoKey: Any] { wrapped.userInfo }

    private let wrapped: _OrderedEncoder
    private weak var parentRef: AnyObject?
    private let index: Int
    private let syncBack: (JSONValue) -> Void

    init<Key: CodingKey>(
        wrapped: _OrderedEncoder,
        parent: _OrderedKeyedContainer<Key>,
        index: Int
    ) {
        self.wrapped = wrapped
        self.parentRef = parent
        self.index = index
        self.syncBack = { [weak parent] val in
            parent?.updateEntry(at: index, value: val)
        }
    }

    private func sync() {
        if let val = wrapped.value {
            syncBack(val)
        }
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        let c = wrapped.container(keyedBy: type)
        // After encoding completes we need to sync. We do this by wrapping.
        return c
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        wrapped.unkeyedContainer()
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        wrapped.singleValueContainer()
    }
}

// MARK: - Unkeyed Container

private final class _OrderedUnkeyedContainer: UnkeyedEncodingContainer {
    var codingPath: [CodingKey]
    var count: Int { elements.count }
    private let encoder: _OrderedEncoder
    private var elements: [JSONValue] = []

    init(codingPath: [CodingKey], encoder: _OrderedEncoder) {
        self.codingPath = codingPath
        self.encoder = encoder
        // Initialize immediately so empty arrays encode as [] not nil
        encoder.value = .array([])
    }

    private func commit() {
        encoder.value = .array(elements)
    }

    private var currentCodingPath: [CodingKey] {
        codingPath + [_JSONKey(intValue: count)!]
    }

    func encodeNil() throws {
        elements.append(.null)
        commit()
    }

    func encode(_ value: Bool) throws {
        elements.append(.bool(value))
        commit()
    }

    func encode(_ value: String) throws {
        elements.append(.string(value))
        commit()
    }

    func encode(_ value: Int) throws {
        elements.append(.int(value))
        commit()
    }

    func encode(_ value: Int8) throws {
        elements.append(.int(Int(value)))
        commit()
    }

    func encode(_ value: Int16) throws {
        elements.append(.int(Int(value)))
        commit()
    }

    func encode(_ value: Int32) throws {
        elements.append(.int(Int(value)))
        commit()
    }

    func encode(_ value: Int64) throws {
        elements.append(.int(Int(value)))
        commit()
    }

    func encode(_ value: UInt) throws {
        elements.append(.int(Int(value)))
        commit()
    }

    func encode(_ value: UInt8) throws {
        elements.append(.int(Int(value)))
        commit()
    }

    func encode(_ value: UInt16) throws {
        elements.append(.int(Int(value)))
        commit()
    }

    func encode(_ value: UInt32) throws {
        elements.append(.int(Int(value)))
        commit()
    }

    func encode(_ value: UInt64) throws {
        elements.append(.int(Int(value)))
        commit()
    }

    func encode(_ value: Float) throws {
        elements.append(.number(Double(value)))
        commit()
    }

    func encode(_ value: Double) throws {
        elements.append(.number(value))
        commit()
    }

    func encode<T: Encodable>(_ value: T) throws {
        let childEncoder = _OrderedEncoder(
            codingPath: currentCodingPath,
            dateFormatter: encoder.dateFormatter
        )
        if let date = value as? Date {
            childEncoder.value = .string(encoder.dateFormatter.string(from: date))
        } else {
            try value.encode(to: childEncoder)
        }
        guard let encoded = childEncoder.value else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: currentCodingPath,
                    debugDescription: "Value did not encode anything."
                )
            )
        }
        elements.append(encoded)
        commit()
    }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> {
        let childEncoder = _OrderedEncoder(
            codingPath: currentCodingPath,
            dateFormatter: encoder.dateFormatter
        )
        let container = _OrderedKeyedContainer<NestedKey>(
            codingPath: currentCodingPath,
            encoder: childEncoder
        )
        // Reserve a slot.
        let index = elements.count
        elements.append(.object([]))
        commit()

        // Return a proxy that syncs back to our elements array.
        let proxy = _UnkeyedNestedKeyedProxy(
            inner: container,
            parent: self,
            index: index,
            childEncoder: childEncoder
        )
        return KeyedEncodingContainer(proxy)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let childEncoder = _OrderedEncoder(
            codingPath: currentCodingPath,
            dateFormatter: encoder.dateFormatter
        )
        let container = _OrderedUnkeyedContainer(
            codingPath: currentCodingPath,
            encoder: childEncoder
        )
        let index = elements.count
        elements.append(.array([]))
        commit()

        return _UnkeyedNestedUnkeyedProxy(
            inner: container,
            parent: self,
            index: index,
            childEncoder: childEncoder
        )
    }

    func superEncoder() -> Encoder {
        let childEncoder = _OrderedEncoder(
            codingPath: currentCodingPath,
            dateFormatter: encoder.dateFormatter
        )
        elements.append(.null)
        commit()
        return childEncoder
    }

    fileprivate func updateElement(at index: Int, value: JSONValue) {
        guard index < elements.count else { return }
        elements[index] = value
        commit()
    }
}

// MARK: - Unkeyed Nested Proxies

private final class _UnkeyedNestedKeyedProxy<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey] { inner.codingPath }
    private let inner: _OrderedKeyedContainer<Key>
    private let childEncoder: _OrderedEncoder
    private let syncBack: (JSONValue) -> Void

    init(
        inner: _OrderedKeyedContainer<Key>,
        parent: _OrderedUnkeyedContainer,
        index: Int,
        childEncoder: _OrderedEncoder
    ) {
        self.inner = inner
        self.childEncoder = childEncoder
        self.syncBack = { [weak parent] val in
            parent?.updateElement(at: index, value: val)
        }
    }

    private func sync() {
        if let val = childEncoder.value { syncBack(val) }
    }

    func encodeNil(forKey key: Key) throws { try inner.encodeNil(forKey: key); sync() }
    func encode(_ value: Bool, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: String, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Int, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Int8, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Int16, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Int32, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Int64, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: UInt, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: UInt8, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: UInt16, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: UInt32, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: UInt64, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Float, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode(_ value: Double, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }
    func encode<T: Encodable>(_ value: T, forKey key: Key) throws { try inner.encode(value, forKey: key); sync() }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        inner.nestedContainer(keyedBy: keyType, forKey: key)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        inner.nestedUnkeyedContainer(forKey: key)
    }

    func superEncoder() -> Encoder { inner.superEncoder() }
    func superEncoder(forKey key: Key) -> Encoder { inner.superEncoder(forKey: key) }
}

private final class _UnkeyedNestedUnkeyedProxy: UnkeyedEncodingContainer {
    var codingPath: [CodingKey] { inner.codingPath }
    var count: Int { inner.count }

    private let inner: _OrderedUnkeyedContainer
    private let childEncoder: _OrderedEncoder
    private let syncBack: (JSONValue) -> Void

    init(
        inner: _OrderedUnkeyedContainer,
        parent: _OrderedUnkeyedContainer,
        index: Int,
        childEncoder: _OrderedEncoder
    ) {
        self.inner = inner
        self.childEncoder = childEncoder
        self.syncBack = { [weak parent] val in
            parent?.updateElement(at: index, value: val)
        }
    }

    private func sync() {
        if let val = childEncoder.value { syncBack(val) }
    }

    func encodeNil() throws { try inner.encodeNil(); sync() }
    func encode(_ value: Bool) throws { try inner.encode(value); sync() }
    func encode(_ value: String) throws { try inner.encode(value); sync() }
    func encode(_ value: Int) throws { try inner.encode(value); sync() }
    func encode(_ value: Int8) throws { try inner.encode(value); sync() }
    func encode(_ value: Int16) throws { try inner.encode(value); sync() }
    func encode(_ value: Int32) throws { try inner.encode(value); sync() }
    func encode(_ value: Int64) throws { try inner.encode(value); sync() }
    func encode(_ value: UInt) throws { try inner.encode(value); sync() }
    func encode(_ value: UInt8) throws { try inner.encode(value); sync() }
    func encode(_ value: UInt16) throws { try inner.encode(value); sync() }
    func encode(_ value: UInt32) throws { try inner.encode(value); sync() }
    func encode(_ value: UInt64) throws { try inner.encode(value); sync() }
    func encode(_ value: Float) throws { try inner.encode(value); sync() }
    func encode(_ value: Double) throws { try inner.encode(value); sync() }
    func encode<T: Encodable>(_ value: T) throws { try inner.encode(value); sync() }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> {
        inner.nestedContainer(keyedBy: keyType)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        inner.nestedUnkeyedContainer()
    }

    func superEncoder() -> Encoder { inner.superEncoder() }
}

// MARK: - Single Value Container

private struct _OrderedSingleValueContainer: SingleValueEncodingContainer {
    var codingPath: [CodingKey]
    private let encoder: _OrderedEncoder

    init(codingPath: [CodingKey], encoder: _OrderedEncoder) {
        self.codingPath = codingPath
        self.encoder = encoder
    }

    mutating func encodeNil() throws {
        encoder.value = .null
    }

    mutating func encode(_ value: Bool) throws {
        encoder.value = .bool(value)
    }

    mutating func encode(_ value: String) throws {
        encoder.value = .string(value)
    }

    mutating func encode(_ value: Int) throws {
        encoder.value = .int(value)
    }

    mutating func encode(_ value: Int8) throws {
        encoder.value = .int(Int(value))
    }

    mutating func encode(_ value: Int16) throws {
        encoder.value = .int(Int(value))
    }

    mutating func encode(_ value: Int32) throws {
        encoder.value = .int(Int(value))
    }

    mutating func encode(_ value: Int64) throws {
        encoder.value = .int(Int(value))
    }

    mutating func encode(_ value: UInt) throws {
        encoder.value = .int(Int(value))
    }

    mutating func encode(_ value: UInt8) throws {
        encoder.value = .int(Int(value))
    }

    mutating func encode(_ value: UInt16) throws {
        encoder.value = .int(Int(value))
    }

    mutating func encode(_ value: UInt32) throws {
        encoder.value = .int(Int(value))
    }

    mutating func encode(_ value: UInt64) throws {
        encoder.value = .int(Int(value))
    }

    mutating func encode(_ value: Float) throws {
        encoder.value = .number(Double(value))
    }

    mutating func encode(_ value: Double) throws {
        encoder.value = .number(value)
    }

    mutating func encode<T: Encodable>(_ value: T) throws {
        // Special-case Date to encode as ISO 8601 string.
        if let date = value as? Date {
            encoder.value = .string(encoder.dateFormatter.string(from: date))
            return
        }
        let childEncoder = _OrderedEncoder(
            codingPath: codingPath,
            dateFormatter: encoder.dateFormatter
        )
        try value.encode(to: childEncoder)
        guard let encoded = childEncoder.value else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value did not encode anything."
                )
            )
        }
        encoder.value = encoded
    }
}

// MARK: - Coding Key Helper

private struct _JSONKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
