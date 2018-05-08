//
//  ViewController.swift
//  TelloTest
//
//  Created by matsumoto keiji on 2018/05/02.
//  Copyright © 2018 keiziweb. All rights reserved.
//

import UIKit
import SwiftSocket

class ViewController: UIViewController {
	static let KEY_SETTING_UNIT_TYPE:String = "KEY_SETTING_UNIT_TYPE"
	static let KEY_UNIT_METER:Int = 0
	static let KEY_UNIT_IMPERIAL:Int = 1

	var _client:UDPClient? = nil
	var _unitType:Int = KEY_UNIT_METER
	
	var _isConnect = false
	var _isSendingAltitude = false

	var _isEnd:Bool = false

	@IBOutlet var _labelAlart: UILabel!
	@IBOutlet var _labelCurrentAlt: UILabel!
	@IBOutlet var _labelUsage: UILabel!
	@IBOutlet var _labelNewAlt: UILabel!
	@IBOutlet var _sliderAlt: UISlider!
	@IBOutlet var _segUnitType: UISegmentedControl!
	
	@IBOutlet var _buttonSend: UIButton!
	override func viewDidLoad() {
		super.viewDidLoad()

		//Load unit setting from user default
		let ud = UserDefaults.standard
		_unitType = ud.integer(forKey:ViewController.KEY_SETTING_UNIT_TYPE)
		if(_unitType < ViewController.KEY_UNIT_METER || _unitType > ViewController.KEY_UNIT_IMPERIAL) {
			_unitType = ViewController.KEY_UNIT_METER
			ud.set(_unitType, forKey: ViewController.KEY_SETTING_UNIT_TYPE)
		}
		self._segUnitType.selectedSegmentIndex = _unitType
	}

	func enableControl() {
		_labelCurrentAlt.isHidden = false
		_labelAlart.isHidden = true
		_labelUsage.isHidden = false
		_buttonSend.isEnabled = true
		_labelNewAlt.isEnabled = true
		_sliderAlt.isEnabled = true
		changeAltSlider(self._sliderAlt)
	}
	
	func disableControl() {
		_labelCurrentAlt.isHidden = true
		_labelAlart.isHidden = false
		_labelUsage.isHidden = true
		_buttonSend.isEnabled = false
		_labelNewAlt.isEnabled = false
		_sliderAlt.isEnabled = false
	}
	
	//connect to Tello
	func connect() {
		disableControl()
		self._client = UDPClient(address: "192.168.10.1", port: 8889)
		if let client = self._client {
			self._isConnect = false
			self._isSendingAltitude = false
			startReceive()
			let res:Result = client.send(data: TelloPacket.createConnectReqPacket())
			if(res.isSuccess) {
			}
		}
	}

	//Close connection and dispose
	func closeConnection() {
		self._isEnd = false
		disableControl()
		self._isConnect = false
		self._isSendingAltitude = false

		//ちょっと待ってから破棄する
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			if let client = self._client {
				client.close()
				self._client = nil
			}
		}
	}
	
	//Start Receive thread
	func startReceive() {
		self._isEnd = true
		DispatchQueue(label: "jp.keiziweb.TALS.queue").async {
			
			while(self._isEnd) {
				if let client = self._client {
					let recvData = client.recv(512) //recvData(data, address, port)
					//print(TelloPacket.packetToHexString(packet: recvData.0!))
					
					//Receive success
					if let data = recvData.0 {
						let bytes:[UInt8] = [UInt8](data)

						//ack
						if(bytes[0] == 0x63) {
							DispatchQueue.main.async {
								self.enableControl()
								self._isConnect = true
							}
							let resGetAlt:Result = client.send(data: TelloPacket.createGetAltitudePacket())
							if(resGetAlt.isFailure) {
								print("Error:Send GetAltitudePacket")
								self.closeConnection()
							}
						}
						//Binary packet
						else if(bytes[0] == 0xcc) {
							//Parse
							if let packet = TelloPacket.parsePacket(data:Data(data)) {
								//4182 == TELLO_CMD_ALT_LIMIT
								if(packet._commandID == 4182) {
									//print(packet._data![0],packet._data![1],packet._data![2])
									
									//Update current altitude label
									let currentAltitude:Int = TelloPacket.littleEndianToInt(packet._data![1], packet._data![2])
									DispatchQueue.main.async {
										self._sliderAlt.value = Float(currentAltitude)
										self._labelNewAlt?.text = self.makeAltitudeString(currentAltitude)
										self._labelCurrentAlt?.text = String(format: NSLocalizedString("CurrentAltFormat",comment:""), self.makeAltitudeString(currentAltitude) )
										
										if(self._isSendingAltitude) {
											UIUtility.showAlertWithOK(vc: self, title: NSLocalizedString("Succeeded",comment:""), message: NSLocalizedString("UpdateSucceeded",comment:""))
										}
										self._isSendingAltitude = false

									}
								}
							}
						}
					}
				}
			}
			
			DispatchQueue.main.async {
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	//Send altitude value to Tello
	@IBAction func tapChangeAltLimit(_ sender: Any) {
		if(!self._isConnect) {
			closeConnection()
			return
		}
		
		let altitude:Int = Int(self._sliderAlt.value)
		if(altitude >= 20) {
			UIUtility.showAlertWithYESAndNO(vc: self, title: NSLocalizedString("confirm",comment:""), message:
				String(format: NSLocalizedString("not_recommend",comment:""), makeAltitudeString(20))
				, handlerYES: {
				(action: UIAlertAction!) in
					self.sendSetAltLimitCommand(altitude: altitude)
			}
				, handlerNO:nil)

		}
		else {
			sendSetAltLimitCommand(altitude: altitude)
		}
	}

	//Send "Set altitude limit command" to Tello.
	public func sendSetAltLimitCommand(altitude:Int) {
		if let client = self._client {
			let resSetAlt:Result = client.send(data: TelloPacket.createSetAltitudePacket(altitudeM: altitude))
			if(resSetAlt.isSuccess) {
				_isSendingAltitude = true
				DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
					if(self._isSendingAltitude) {
						self.closeConnection()
						UIUtility.showAlertWithOK(vc: self, title: NSLocalizedString("error",comment:""), message: NSLocalizedString("FaultGetAlt",comment:""))
					}
				}

				let resGetAlt:Result = client.send(data: TelloPacket.createGetAltitudePacket())
				if(resGetAlt.isFailure) {
					print("Error:Send GetAltitudePacket")
				}
			}
			else {
				print("Error:Send SetAltitudePacket")
			}
		}
	}

	//changeUnitType save type
	@IBAction func changeUnitType(_ sender: UISegmentedControl) {
		let ud = UserDefaults.standard
		_unitType = sender.selectedSegmentIndex
		ud.set(_unitType, forKey: ViewController.KEY_SETTING_UNIT_TYPE)
	}
	
	//changeAltSlider update label
	@IBAction func changeAltSlider(_ sender: UISlider) {
		let altitude:Int = Int(self._sliderAlt.value)
		self._sliderAlt.value = Float(altitude)
		self._labelNewAlt?.text = self.makeAltitudeString(Int(sender.value))
	}

	//make Altitude string with unit type
	func makeAltitudeString(_ altitude:Int)->String {
		if(_unitType == ViewController.KEY_UNIT_METER) {
			return String(format: "%d m", altitude)
		}
		else {
			return String(format: "%.1f ft", Float(altitude) * 3.2808)
		}
	}
	
	//Takeoff
	@IBAction func tapTakeoff(_ sender: Any) {
		if let client = self._client {
			let res:Result = client.send(data: TelloPacket.takeOffPacket)
			if(!res.isSuccess) {
				print("Error:Send TakeOff")
			}
		}

	}

	//Land
	@IBAction func tapLand(_ sender: Any) {
		if let client = self._client {
			let res:Result = client.send(data: TelloPacket.landPacket)
			if(!res.isSuccess) {
				print("Error:Send Land")
			}
		}

	}
}

