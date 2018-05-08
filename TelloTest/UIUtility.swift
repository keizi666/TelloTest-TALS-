//
//  UIUtility.swift
//  Quiz
//
//  Created by matsumoto keiji on 2017/05/29.
//  Copyright © 2017年 matsumoto keiji. All rights reserved.
//

import Foundation
import UIKit

struct UIUtility {
	//OKボタンのアラートを出す
	static func showAlertWithOK(vc:UIViewController,title:String,message:String,handler: ((UIAlertAction) -> Swift.Void)? = nil,completion: (() -> Swift.Void)? = nil) {
		let alert:UIAlertController = UIAlertController(title:title, message:message, preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment:""), style: UIAlertActionStyle.default, handler:handler))
		vc.present(alert, animated: true, completion:completion)
	}
	
	//OKボタンとキャンセルのアラートを出す
	static func showAlertWithOKAndCansel(vc:UIViewController,title:String,message:String,handlerOK: ((UIAlertAction) -> Swift.Void)? = nil,handlerCancel: ((UIAlertAction) -> Swift.Void)? = nil,completion: (() -> Swift.Void)? = nil) {
		let alert:UIAlertController = UIAlertController(title:title, message:message, preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment:""), style: UIAlertActionStyle.default, handler:handlerCancel))
		alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment:""), style: UIAlertActionStyle.default, handler:handlerOK))

		vc.present(alert, animated: true, completion:completion)
	}
	
	//YESボタンとNOのアラートを出す
	static func showAlertWithYESAndNO(vc:UIViewController,title:String,message:String,handlerYES: ((UIAlertAction) -> Swift.Void)? = nil,handlerNO: ((UIAlertAction) -> Swift.Void)? = nil,completion: (() -> Swift.Void)? = nil) {
		let alert:UIAlertController = UIAlertController(title:title, message:message, preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("no", comment:""), style: UIAlertActionStyle.default, handler:handlerNO))
		alert.addAction(UIAlertAction(title: NSLocalizedString("yes", comment:""), style: UIAlertActionStyle.default, handler:handlerYES))

		vc.present(alert, animated: true, completion:completion)
		
	}
	
	//アクションシートを表示する
	static func showAction(vc:UIViewController,title:String,message:String,actions:[UIAlertAction],isNeedCancel:Bool) {
		let alertSheet = UIAlertController(title:title, message:message, preferredStyle: UIAlertControllerStyle.actionSheet)
		

		for action in actions {
			alertSheet.addAction(action)
		}

		if(isNeedCancel) {
			let actionCancel = UIAlertAction(title: NSLocalizedString("cancel",comment:""), style: UIAlertActionStyle.cancel, handler: {
				(action: UIAlertAction!) in
			})

			alertSheet.addAction(actionCancel)
		}
		vc.present(alertSheet, animated: true, completion: nil)

	}
	
	
	
	
}

