/*

Converts A class to a dictionary, used for serializing dictionaries to JSON

Supported objects:
- Serializable derived classes
- Arrays of Serializable
- NSData
- String, Numeric, and all other NSJSONSerialization supported objects

*/

import Foundation

public class Serializable : NSObject{
  
  func toDictionary() -> NSDictionary {
    var aClass : AnyClass? = self.dynamicType
    var propertiesCount : CUnsignedInt = 0
    let propertiesInAClass : UnsafeMutablePointer<objc_property_t> = class_copyPropertyList(aClass, &propertiesCount)
    var propertiesDictionary : NSMutableDictionary = NSMutableDictionary()
    
    for var i = 0; i < Int(propertiesCount); i++ {
      var property = propertiesInAClass[i]
      var propName = NSString(CString: property_getName(property), encoding: NSUTF8StringEncoding)
      var propType = property_getAttributes(property)
      var propValue : AnyObject! = self.valueForKey(propName! as String);
      
      if propValue is Serializable {
        propertiesDictionary.setValue((propValue as! Serializable).toDictionary(), forKey: (propName as! String))
      } else if propValue is Array<Serializable> {
        var subArray = Array<NSDictionary>()
        for item in (propValue as! Array<Serializable>) {
          subArray.append(item.toDictionary())
        }
        propertiesDictionary.setValue(subArray, forKey: propName! as String)
      } else if propValue is NSData {
        propertiesDictionary.setValue((propValue as! NSData).base64EncodedStringWithOptions(nil), forKey: propName! as String)
      } else if propValue is Bool {
        propertiesDictionary.setValue((propValue as! Bool).boolValue, forKey: propName! as String)
      } else if propValue is NSDate {
        var date = propValue as! NSDate
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "Z"
        var dateString = NSString(format: "/Date(%.0f000%@)/", date.timeIntervalSince1970, dateFormatter.stringFromDate(date))
        propertiesDictionary.setValue(dateString, forKey: propName! as String)
      } else {
        propertiesDictionary.setValue(propValue, forKey: propName! as String)
      }
    }
    
    return propertiesDictionary
  }
  
  func toJson() -> NSData! {
    var dictionary = self.toDictionary()
    var err: NSError?
    return NSJSONSerialization.dataWithJSONObject(dictionary, options:NSJSONWritingOptions(0), error: &err)
  }
  
  public func toJsonString() -> NSString! {
    return NSString(data: self.toJson(), encoding: NSUTF8StringEncoding)
  }
  
  override init() { }
}