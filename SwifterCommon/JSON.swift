//
//  JSON.swift
//  Swifter
//
//  Copyright (c) 2014 Matt Donnelly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

let JSTrue = JSON(true)
let JSFalse = JSON(false)

let JSONNull = JSON.JSONNull

enum JSON : Equatable, Printable {

    enum Encodings : String {
        case base64 = "data:text/plain;base64,"
    }
    
    case JSONString(Swift.String)
    case JSONNumber(Double)
    case JSONDictionary(Dictionary<String, JSON>)
    case JSONArray(Array<JSON>)
    case JSONBool(Bool)
    case JSONNull
    
    case _Invalid
    
    init(_ value: Bool?) {
        if let bool = value {
            self = .JSONBool(bool)
        }
        else {
            self = .JSONNull
        }
    }
    
    init(_ value: Double?) {
        if let number = value {
            self = .JSONNumber(number)
        }
        else {
            self = .JSONNull
        }
    }
    
    init(_ value: Int?) {
        if let number = value {
            self = .JSONNumber(Double(number))
        }
        else {
            self = .JSONNull
        }
    }
    
    init(_ value: String?) {
        if let string = value {
            self = .JSONString(string)
        }
        else {
            self = .JSONNull
        }
    }
    
    init(_ value: Array<JSON>?) {
        if let array = value {
            self = .JSONArray(array)
        }
        else {
            self = .JSONNull
        }
    }
    
    init(_ value: Dictionary<String, JSON>?) {
        if let dict = value {
            self = .JSONDictionary(dict)
        }
        else {
            self = .JSONNull
        }
    }
    
    init(_ bytes: Byte[], encoding: Encodings = Encodings.base64) {
        let data = NSData(bytes: bytes, length: bytes.count)
        
        switch encoding {
        case .base64:
            let encoded = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding76CharacterLineLength)
            self = .JSONString("\(encoding.toRaw())\(encoded)")
        }
    }
    
    init(_ rawValue: AnyObject?) {
        if let value : AnyObject = rawValue {
            switch value {
            case let array as NSArray:
                var newArray : JSON[] = []
                for item : AnyObject in array {
                    newArray += JSON(item)
                }
                self = .JSONArray(newArray)
                
            case let dict as NSDictionary:
                var newDict : Dictionary<String, JSON> = [:]
                for (k : AnyObject, v : AnyObject) in dict {
                    if let key = k as? String {
                        newDict[key] = JSON(v)
                    }
                    else {
                        assert(true, "Invalid key type; expected String")
                        self = ._Invalid
                        return
                    }
                }
                self = .JSONDictionary(newDict)
                
            case let string as NSString:
                self = .JSONString(string)
                
            case let number as NSNumber:
                if number.objCType == "c" {
                    self = .JSONBool(number.boolValue)
                }
                else {
                    self = .JSONNumber(number.doubleValue)
                }
                
            case let null as NSNull:
                self = .JSONNull
                
            default:
                assert(true, "This location should never be reached")
                self = ._Invalid
            }
        }
        else {
            self = .JSONNull
        }
    }

    static func parse(jsonData : NSData, error: NSErrorPointer) -> JSON? {
        var JSONDictionary : AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonData, options: .MutableContainers, error: error)

        return JSONDictionary == nil ? nil : JSON(JSONDictionary)
    }

    static func parse(jsonString : String, error: NSErrorPointer) -> JSON? {
        var data = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)

        return parse(data, error: error)
    }

    func stringify(indent: String = "  ") -> String? {
        switch self {
        case ._Invalid:
            assert(true, "The JSON value is invalid")
            return nil
            
        default:
            return _prettyPrint(indent, 0)
        }
    }

    var string : String? {
        switch self {
        case .JSONString(let value):
            return value
            
        default:
            return nil
        }
    }

    var integer : Int? {
        switch self {
        case .JSONNumber(let value):
            return Int(value)
            
        default:
            return nil
        }
    }

    var double : Double? {
        switch self {
        case .JSONNumber(let value):
            return value

        default:
            return nil
        }
    }

    var dictionary : Dictionary<String, JSON>? {
        switch self {
        case .JSONDictionary(let value):
            return value
            
        default:
            return nil
        }
    }

    var array : Array<JSON>? {
        switch self {
        case .JSONArray(let value):
            return value
            
        default:
            return nil
        }
    }

    var bool : Bool? {
        switch self {
        case .JSONBool(let value):
            return value

        default:
            return nil
        }
    }

    var decodedString: Byte[]? {
        switch self {
        case .JSONString(let encodedStringWithPrefix):
            if encodedStringWithPrefix.hasPrefix(Encodings.base64.toRaw()) {
                let encodedString = encodedStringWithPrefix.substringFromIndex(Encodings.base64.toRaw().lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
                let decoded = NSData(base64EncodedString: encodedString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                
                let bytesPointer = UnsafePointer<Byte>(decoded.bytes)
                let bytes = UnsafeArray<Byte>(start: bytesPointer, length: decoded.length)
                return Byte[](bytes)
            }
            
        default:
            return nil
        }
            
        return nil
    }

    subscript(key: String) -> JSON? {
        switch self {
        case .JSONDictionary(let dict):
            return dict[key]
            
        default:
            return nil
        }
    }

    subscript(index: Int) -> JSON? {
        switch self {
        case .JSONArray(let array):
            return array[index]
            
        default:
            return nil
        }
    }

    var description: String {
        if let jsonString = stringify() {
            return jsonString
        }
        else {
            return "<INVALID JSON>"
        }
    }

}

func ==(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs, rhs) {
    case (.JSONNull, .JSONNull):
        return true
        
    case (.JSONBool(let lhsValue), .JSONBool(let rhsValue)):
        return lhsValue == rhsValue

    case (.JSONString(let lhsValue), .JSONString(let rhsValue)):
        return lhsValue == rhsValue

    case (.JSONNumber(let lhsValue), .JSONNumber(let rhsValue)):
        return lhsValue == rhsValue

    case (.JSONArray(let lhsValue), .JSONArray(let rhsValue)):
        return lhsValue == rhsValue

    case (.JSONDictionary(let lhsValue), .JSONDictionary(let rhsValue)):
        return lhsValue == rhsValue
        
    default:
        return false
    }
}

extension JSON {

    func _prettyPrint(indent: String, _ level: Int) -> String {
        let currentIndent = join(indent, map(0...level, { (item: Int) in "" }))
        let nextIndent = currentIndent + "  "
        
        switch self {
        case .JSONBool(let bool):
            return bool ? "true" : "false"
            
        case .JSONNumber(let number):
            return "\(number)"
            
        case .JSONString(let string):
            return "\"\(string)\""
            
        case .JSONArray(let array):
            return "[\n" + join(",\n", array.map({ "\(nextIndent)\($0._prettyPrint(indent, level + 1))" })) + "\n\(currentIndent)]"
            
        case .JSONDictionary(let dict):
            return "{\n" + join(",\n", map(dict, { "\(nextIndent)\"\($0)\" : \($1._prettyPrint(indent, level + 1))"})) + "\n\(currentIndent)}"
            
        case .JSONNull:
            return "null"
            
        case ._Invalid:
            assert(true, "This should never be reached")
            return ""
        }
    }

}

extension JSON : IntegerLiteralConvertible {

    static func convertFromIntegerLiteral(value: Int) -> JSON {
        return .JSONNumber(Double(value))
    }

}

extension JSON : FloatLiteralConvertible {

    static func convertFromFloatLiteral(value: Double) -> JSON {
        return .JSONNumber(value)
    }

}

extension JSON : StringLiteralConvertible {

    static func convertFromStringLiteral(value: String) -> JSON {
        return .JSONString(value)
    }

    static func convertFromExtendedGraphemeClusterLiteral(value: String) -> JSON {
        return .JSONString(value)
    }

}

extension JSON : ArrayLiteralConvertible {

    static func convertFromArrayLiteral(elements: JSON...) -> JSON {
        return .JSONArray(elements)
    }

}

extension JSON : DictionaryLiteralConvertible {

    static func convertFromDictionaryLiteral(elements: (String, JSON)...) -> JSON {
        var dict = Dictionary<String, JSON>()
        for (k, v) in elements {
            dict[k] = v
        }
        
        return .JSONDictionary(dict)
    }

}
