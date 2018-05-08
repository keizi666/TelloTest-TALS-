//
//  General.swift
//  norikae
//
//  Created by matsumoto keiji on 2017/05/29.
//  Copyright © 2017年 matsumoto keiji. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

struct General {
	//現在の日時（年、月、日、時、分、秒）を返す
	static func getNowDateAndTime() -> (Int,Int,Int,Int,Int,Int) {
		let now = Date()
		let cal = Calendar.current
		let dataComps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: now)
		return (dataComps.year!,dataComps.month!,dataComps.day!,dataComps.hour!,dataComps.minute!,dataComps.second!)
	}
	
	static func stringToDate(format:String,date:String)->Date {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = format
		dateFormatter.timeZone = TimeZone.ReferenceType.local
		dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
		return dateFormatter.date(from: date)!
	}
	
	static func dateToString(format: String,date: Date) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = format
		dateFormatter.timeZone = TimeZone.ReferenceType.local
		dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
		
		return dateFormatter.string(from: date)
	}


	//URLをRequestにする
	static func urlToRequest(_ urlString:String) -> NSURLRequest? {
		
		let encodedURL = General.urlEncode(url:urlString)
		if(encodedURL != nil) {
			let myUrl = NSURL(string: encodedURL!)
			
			return  NSURLRequest(url:myUrl! as URL)
		}
		return nil
	}
	
	//URLエンコードをする
	static func urlEncode(url:String) -> String? {
		return url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
	}
	
	//指定範囲内の乱数を返す
	static func random(lower: Int, upper: Int) -> Int {
		guard upper >= lower else {
			return 0
		}
		
		return (Int)(arc4random_uniform((UInt32)(upper - lower)) + ((UInt32)(lower)))
	}
	
	//UIImageをリサイズする
	static func resizeImage(newSize:CGSize,imageSrc:UIImage)->UIImage? {
		UIGraphicsBeginImageContext(CGSize(width:newSize.width, height:newSize.height))
		imageSrc.draw(in: CGRect(x:0, y:0, width:newSize.width, height:newSize.height))
		let imageResized = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return imageResized
	}
	
	//イメージを切り出す
	static func imageByCropping(imageToCrop:UIImage,toRect:CGRect) -> UIImage {
		let cropRef   = imageToCrop.cgImage!.cropping(to: toRect)
		let cropImage = UIImage(cgImage: cropRef!)
		return cropImage
	}
	
	func CheckReachability(host_name:String)->Bool{
		
		let reachability = SCNetworkReachabilityCreateWithName(nil, host_name)!
		var flags = SCNetworkReachabilityFlags.connectionAutomatic
		if !SCNetworkReachabilityGetFlags(reachability, &flags) {
			return false
		}
		let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
		let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
		return (isReachable && !needsConnection)
	}
	
	//イメージのピクセルを取る
	static func getPixcelFromImage(image:UIImage,x:Int,y:Int) -> Int {
		
		let pixelBuf:Data? = image.cgImage?.dataProvider?.data as Data?
		
		if let pixelBuf = pixelBuf {
			let bytesPerRow:Int = image.cgImage!.bytesPerRow
			
			// 画素アドレス（バッファ内インデクス）を求める
			//let pixelAddr:Int = ((Int(image.size.width) * y) + x) * 4   // 1 Pixel==4 Byte
			let pixelAddr = bytesPerRow * y + x * 4
			
			// 画素成分が、Green, Blue, Red, Alpha の順に並んでいる場合
			let r:Int = Int(pixelBuf[ pixelAddr ])
			let g:Int = Int(pixelBuf[ pixelAddr+1])
			let b:Int = Int(pixelBuf[ pixelAddr+2])
			let a:Int = Int(pixelBuf[ pixelAddr+3])
			
			// UIColor オブジェクト作成
			let color:Int = (a << 24) + (r << 16) + (g << 8) + b
			
			return color
		}
		return 0
	}
	
	//文字列の描画サイズを取得
	static func getTextSize(text:String,fontSize:CGFloat)->CGSize {
		let font = UIFont.boldSystemFont(ofSize: fontSize)
		return text.size(withAttributes: [NSAttributedStringKey.font : font])
	}
	
	//ふち付きの文字を描画する
	static func drawTextCanvas(context:CGContext,width:CGFloat,x:CGFloat,y:CGFloat,text:String,outlineColor:UIColor,outlineWidth:CGFloat,textColor:UIColor, fontSize:CGFloat)
	{
		var fontSize = fontSize
		var x = x
		
		let font = UIFont.boldSystemFont(ofSize: fontSize)
		let textWidth = text.size(withAttributes: [NSAttributedStringKey.font : font]).width
		
		
		if(textWidth > width && text.count > 2) {
			fontSize = width / textWidth * fontSize
			x = 0
			if(fontSize < 10) {
				fontSize = 10
			}
		}
		else if(x == 0) {
			x = (width - textWidth) / 2.0
		}
		
		//ラベルを描く
		let outlineAttributes = [
			NSAttributedStringKey.font: UIFont.systemFont(ofSize: fontSize),
			NSAttributedStringKey.strokeWidth:outlineWidth,
			NSAttributedStringKey.strokeColor: outlineColor
			] as [NSAttributedStringKey : Any]
		text.draw(at:CGPoint(x:x,y:y), withAttributes: outlineAttributes)
		
		
		let stringAttributes = [
			NSAttributedStringKey.font: UIFont.systemFont(ofSize: fontSize),
			NSAttributedStringKey.strokeWidth:0,
			NSAttributedStringKey.foregroundColor: textColor
			] as [NSAttributedStringKey : Any]
		
		text.draw(at:CGPoint(x:x,y:y), withAttributes: stringAttributes)
		
		context.strokePath()
	}
	
	
}
extension NSURL {
	var fragments: [String : String] {
		var results: [String : String] = [:]
		guard let urlComponents = NSURLComponents(string: self.absoluteString!), let items = urlComponents.queryItems else {
			return results
		}
		
		for item in items {
			results[item.name] = item.value
		}
		
		return results
	}
}

extension UIColor {
	//16進数文字列をUIColorにする
	class func hexStr(hexStr:NSString,alpha:CGFloat) -> UIColor {
		let alpha = alpha
		var hexStr = hexStr
		hexStr = hexStr.replacingOccurrences(of: "#", with: "") as NSString
		let scanner = Scanner(string: hexStr as String)
		var color: UInt32 = 0
		if scanner.scanHexInt32(&color) {
			let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
			let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
			let b = CGFloat(color & 0x0000FF) / 255.0
			return UIColor(red:r,green:g,blue:b,alpha:alpha)
		} else {
			print("invalid hex string")
			return UIColor.white
		}
	}
	
	//16進数をUIColorにする
	class func hex(hex:UInt32) -> UIColor {
		let color: UInt32 = hex
		
		let a = CGFloat((color & 0xFF000000) >> 24) / 255.0
		let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
		let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
		let b = CGFloat(color & 0x0000FF) / 255.0
		return UIColor(red:r,green:g,blue:b,alpha:a)
	}
	
	//16進数カラーをRGBAに分解する
	class func disassembleRGBA(hex:UInt32) -> (r:Int,g:Int,b:Int,a:Int) {
		let color: UInt32 = hex
		
		let a = Int((color & 0xFF000000) >> 24)
		let r = Int((color & 0xFF0000) >> 16)
		let g = Int((color & 0x00FF00) >> 8)
		let b = Int(color & 0x0000FF)
		return (r:r,g:g,b:b,a:a)
	}
	
	//16進数カラーをRGBAに分解する
	class func toRGBAHex(r:UInt32,g:UInt32,b:UInt32,a:UInt32) -> UInt32 {
		return (a << 24) + (r << 16) + (g << 8) + b
	}
}

