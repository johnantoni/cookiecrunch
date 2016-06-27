//
//  Extensions.swift
//  CookieCrunch
//
//  Created by Razeware on 13/04/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import Foundation

extension Dictionary {
  
  // Loads a JSON file from the app bundle into a new dictionary
  static func loadJSONFromBundle(filename: String) -> Dictionary <String, AnyObject>? {
    var dataOK: NSData
    var dictionaryOK: NSDictionary = NSDictionary()
    if let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json") {
      let _: NSError?
      do {
        let data = try NSData(contentsOfFile: path, options: NSDataReadingOptions()) as NSData!
        dataOK = data
      }
      catch {
        print("Could not load level file: \(filename), error: \(error)")
        return nil
      }
      do {
        let dictionary = try NSJSONSerialization.JSONObjectWithData(dataOK, options: NSJSONReadingOptions()) as AnyObject!
        dictionaryOK = (dictionary as! NSDictionary as? Dictionary <String, AnyObject>)!
      }
      catch {
        print("Level file '\(filename)' is not valid JSON: \(error)")
        return nil
      }
    }
    return dictionaryOK as? Dictionary <String, AnyObject>
  }
  
}
