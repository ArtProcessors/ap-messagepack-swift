import Foundation

extension _MessagePackDecoder {
    final class KeyedContainer<Key> where Key: CodingKey {
        lazy var nestedContainers: [String: MessagePackDecodingContainer] = {
            guard let count = self.count else {
                return [:]
            }
            
            var nestedContainers: [String: MessagePackDecodingContainer] = [:]
            
            let unkeyedContainer = UnkeyedContainer(data: self.data.suffix(from: self.index), codingPath: self.codingPath, userInfo: self.userInfo)
            unkeyedContainer.count = count * 2
            
            do {
                var iterator = unkeyedContainer.nestedContainers.makeIterator()

                for _ in 0..<count {
                    guard let keyContainer = iterator.next() as? _MessagePackDecoder.SingleValueContainer,
                        let container = iterator.next() else {
                        fatalError() // FIXME
                    }
                    
                    let key = try keyContainer.decode(String.self)
                    container.codingPath += [AnyCodingKey(stringValue: key)!]
                    nestedContainers[key] = container
                }
            } catch {
                fatalError("\(error)") // FIXME
            }
            
            self.index = unkeyedContainer.index
            
            return nestedContainers
        }()
        
        lazy var count: Int? = {
            do {
                let format = try self.readByte()
                switch format {
                case 0x80...0x8f:
                    return Int(format & 0x0F)
                case 0xde:
                    return Int(try read(UInt16.self))
                case 0xdf:
                    return Int(try read(UInt32.self))
                default:
                    return nil
                }
            } catch {
                return nil
            }
        }()

        var data: Data
        var index: Data.Index
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            return self.codingPath + [key]
        }
        
        init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            self.index = self.data.startIndex
        }
        
        func checkCanDecodeValue(forKey key: Key) throws {
            guard self.contains(key) else {
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "key not found: \(key)")
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
}

extension _MessagePackDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        return self.nestedContainers.keys.map{ Key(stringValue: $0)! }
    }
    
    func contains(_ key: Key) -> Bool {
        return self.nestedContainers.keys.contains(key.stringValue)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        try checkCanDecodeValue(forKey: key)

        let nestedContainer = self.nestedContainers[key.stringValue]

        switch nestedContainer {
        case let singleValueContainer as _MessagePackDecoder.SingleValueContainer:
            return singleValueContainer.decodeNil()
        case is _MessagePackDecoder.UnkeyedContainer,
             is _MessagePackDecoder.KeyedContainer<AnyCodingKey>:
            return false
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "cannot decode nil for key: \(key)")
            throw DecodingError.typeMismatch(Any?.self, context)
        }
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        try checkCanDecodeValue(forKey: key)
        
        let container = self.nestedContainers[key.stringValue]!
        let decoder = MessagePackDecoder()
        let value = try decoder.decode(T.self, from: container.data)
        
        return value
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        try checkCanDecodeValue(forKey: key)
        
        guard let unkeyedContainer = self.nestedContainers[key.stringValue] as? _MessagePackDecoder.UnkeyedContainer else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }
        
        return unkeyedContainer
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        try checkCanDecodeValue(forKey: key)
        
        guard let keyedContainer = self.nestedContainers[key.stringValue] as? _MessagePackDecoder.KeyedContainer<NestedKey> else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }
        
        return KeyedDecodingContainer(keyedContainer)
    }
    
    func superDecoder() throws -> Decoder {
        return _MessagePackDecoder(data: self.data)
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        let decoder = _MessagePackDecoder(data: self.data)
        decoder.codingPath = [key]
        
        return decoder
    }
}

extension _MessagePackDecoder.KeyedContainer: MessagePackDecodingContainer {}
