/*

Converts A class to a dictionary, used for serializing dictionaries to JSON

Supported objects:
- Serializable derived classes (sub classes)
- Arrays of Serializable
- NSData
- String, Numeric, and all other NSJSONSerialization supported objects

*/

import Foundation

open class Serializable: NSObject {
    fileprivate class SortedDictionary : NSMutableDictionary {
        var _dictionary = [String: AnyObject]()
      
        override var count : Int {
            return _dictionary.count
        }
      
        override func keyEnumerator() -> NSEnumerator {
            let sortedKeys : NSArray = _dictionary.keys.sorted() as NSArray
            return sortedKeys.objectEnumerator()
        }
      
        override func setValue(_ value: Any?, forKey key: String) {
            _dictionary[key] = value as AnyObject?
        }
      
        override func object(forKey aKey: Any) -> Any? {
            if let key = aKey as? String {
                return _dictionary[key]
            }
          
            return nil
        }
    }
  
  
    open func formatKey(_ key: String) -> String {
        return key
    }
  
    open func formatValue(_ value: AnyObject?, forKey: String) -> AnyObject? {
        return value
    }
  
    func setValue(_ dictionary: NSDictionary, value: AnyObject?, forKey: String) {
        dictionary.setValue(formatValue(value, forKey: forKey), forKey: formatKey(forKey))
    }
  
    /**
    Converts the class to a dictionary.

    - returns: The class as an NSDictionary.
    */
    open func toDictionary() -> NSDictionary {
        let propertiesDictionary = SortedDictionary()
        let mirror = Mirror(reflecting: self)
        for (propName, propValue) in mirror.children {
            if let propValue: AnyObject = self.unwrap(propValue) as AnyObject?, let propName = propName {
                if let serializablePropValue = propValue as? Serializable {
                    setValue(propertiesDictionary, value: serializablePropValue.toDictionary(), forKey: propName)
                } else if let arrayPropValue = propValue as? [Serializable] {
                    var subArray = [NSDictionary]()
                    for item in arrayPropValue {
                        subArray.append(item.toDictionary())
                    }
                    setValue(propertiesDictionary, value: subArray as AnyObject?, forKey: propName)
                } else if propValue is Int || propValue is Double || propValue is Float {
                    setValue(propertiesDictionary, value: propValue, forKey: propName)
                } else if let dataPropValue = propValue as? Data {
                    setValue(propertiesDictionary, value: dataPropValue.base64EncodedString(options: .lineLength64Characters) as AnyObject?, forKey: propName)
                } else if let datePropValue = propValue as? Date {
                    setValue(propertiesDictionary, value: datePropValue.timeIntervalSince1970 as AnyObject?, forKey: propName)
                } else if let boolPropValue = propValue as? Bool {
                    setValue(propertiesDictionary, value: boolPropValue as AnyObject?, forKey: propName)
                } else {
                    setValue(propertiesDictionary, value: propValue, forKey: propName)
                }
            }
            else if let propValue:Int8 = propValue as? Int8 {
                setValue(propertiesDictionary, value: NSNumber(value: propValue as Int8), forKey: propName!)
            }
            else if let propValue:Int16 = propValue as? Int16 {
                setValue(propertiesDictionary, value: NSNumber(value: propValue as Int16), forKey: propName!)
            }
            else if let propValue:Int32 = propValue as? Int32 {
                setValue(propertiesDictionary, value: NSNumber(value: propValue as Int32), forKey: propName!)
            }
            else if let propValue:Int64 = propValue as? Int64 {
                setValue(propertiesDictionary, value: NSNumber(value: propValue as Int64), forKey: propName!)
            }
            else if let propValue:UInt8 = propValue as? UInt8 {
                setValue(propertiesDictionary, value: NSNumber(value: propValue as UInt8), forKey: propName!)
            }
            else if let propValue:UInt16 = propValue as? UInt16 {
                setValue(propertiesDictionary, value: NSNumber(value: propValue as UInt16), forKey: propName!)
            }
            else if let propValue:UInt32 = propValue as? UInt32 {
                setValue(propertiesDictionary, value: NSNumber(value: propValue as UInt32), forKey: propName!)
            }
            else if let propValue:UInt64 = propValue as? UInt64 {
                setValue(propertiesDictionary, value: NSNumber(value: propValue as UInt64), forKey: propName!)
            }
        }

        return propertiesDictionary
    }

    /**
    Converts the class to JSON.

    - returns: The class as JSON, wrapped in NSData.
    */
    open func toJson(_ prettyPrinted : Bool = false) -> Data? {
        let dictionary = self.toDictionary()

        if JSONSerialization.isValidJSONObject(dictionary) {
            do {
                let json = try JSONSerialization.data(withJSONObject: dictionary, options: (prettyPrinted ? .prettyPrinted : JSONSerialization.WritingOptions()))
                return json
            } catch let error as NSError {
                print("ERROR: Unable to serialize json, error: \(error)")
            }
        }

        return nil
    }

    /**
    Converts the class to a JSON string.

    - returns: The class as a JSON string.
    */
    open func toJsonString(_ prettyPrinted : Bool = false) -> String? {
        if let jsonData = self.toJson(prettyPrinted) {
            return NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as String?
        }

        return nil
    }
  
  
    /**
    Unwraps 'any' object. See http://stackoverflow.com/questions/27989094/how-to-unwrap-an-optional-value-from-any-type

    - returns: The unwrapped object.
    */
    func unwrap(_ any:Any) -> Any? {
      
        let mi = Mirror(reflecting: any)
        if mi.displayStyle != .optional {
            return any
        }
      
        if mi.children.count == 0 { return nil }
        let (_, some) = mi.children.first!
        return some
    }
  
    func isEnum(any: Any) -> Bool {
        return Mirror(reflecting: any).displayStyle == .enum
    }
}
