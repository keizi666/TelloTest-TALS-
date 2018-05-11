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

	@IBOutlet var _labelSSID: UILabel!

	var _carrentAltitude:Int = 0

	@IBOutlet var _labelRegion: UILabel!
	@IBOutlet var _labelAlart: UILabel!
	@IBOutlet var _labelCurrentAlt: UILabel!
	@IBOutlet var _labelUsage: UILabel!
	@IBOutlet var _labelNewAlt: UILabel!
	@IBOutlet var _labelVersion: UILabel!
	@IBOutlet var _sliderAlt: UISlider!
	@IBOutlet var _segUnitType: UISegmentedControl!
	
	@IBOutlet var _buttonSend: UIButton!
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let data:[UInt8] = [0x00,0x0c,0x54,0x45 ,0x4c ,0x4c ,0x4f ,0x2d ,0x4d ,0x32 ]
		print(TelloPacket.dataToAsciiString(data: data))
		
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
							client.send(data: TelloPacket.build11Packet(type: 0x48, command: TelloPacket.TELLO_CMD_REGION))
							client.send(data: TelloPacket.build11Packet(type: 0x48, command: TelloPacket.TELLO_CMD_VERSION_STRING))
							client.send(data: TelloPacket.build11Packet(type: 0x48, command: TelloPacket.TELLO_CMD_SSID))
						}
						//Binary packet
						else if(bytes[0] == 0xcc) {
							//Parse
							if let packet = TelloPacket.parsePacket(data:Data(data)) {

								//TELLO_CMD_ALT_LIMIT
								if(packet._commandID == 4182) {
									//print(packet._data![0],packet._data![1],packet._data![2])
									
									//Update current altitude label
									self._carrentAltitude = TelloPacket.littleEndianToInt(packet._data![1], packet._data![2])
									DispatchQueue.main.async {
										self._sliderAlt.value = Float(self._carrentAltitude)
										self._labelNewAlt?.text = self.makeAltitudeString(self._carrentAltitude)
										self._labelCurrentAlt?.text = String(format: NSLocalizedString("CurrentAltFormat",comment:""), self.makeAltitudeString(self._carrentAltitude) )
										
										if(self._isSendingAltitude) {
											UIUtility.showAlertWithOK(vc: self, title: NSLocalizedString("Succeeded",comment:""), message: NSLocalizedString("UpdateSucceeded",comment:""))
										}
										self._isSendingAltitude = false
									}
								}
								//TELLO_CMD_REGION
								else if(packet._commandID == TelloPacket.TELLO_CMD_REGION) {
									DispatchQueue.main.async {
										self._labelRegion?.text = String(format: NSLocalizedString("Region",comment:""), TelloPacket.dataToAsciiString(data: packet._data))
										
/*										if var data = packet._data {
											data[0] = 0x20
											print(TelloPacket.packetToHexString(packet: data))
											print(String(bytes: data, encoding: .ascii)!)
											self._labelRegion?.text = String(format: NSLocalizedString("Region",comment:""), String(bytes: data, encoding: .ascii)!)
										}
*/									}
								}
								//TELLO_CMD_VERSION_STRING
								else if(packet._commandID == TelloPacket.TELLO_CMD_VERSION_STRING) {

									DispatchQueue.main.async {
										self._labelVersion?.text = String(format: NSLocalizedString("Version",comment:""), TelloPacket.dataToAsciiString(data: packet._data))
									}
								}
								//TELLO_CMD_SSID
								else if(packet._commandID == TelloPacket.TELLO_CMD_SSID) {
									
									DispatchQueue.main.async {
										var ssid = String(format: NSLocalizedString("SSID",comment:""), TelloPacket.dataToAsciiString(data: packet._data))
										ssid = ssid.replacingOccurrences(of:" ", with:"")
										self._labelSSID?.text = ssid
										
/*										if var data = packet._data {
											data[0] = 0x20
											data[1] = 0x20
											print(TelloPacket.packetToHexString(packet: data))
											var ssid = String(format: NSLocalizedString("SSID",comment:""), String(bytes: data, encoding: .ascii)!)
											ssid = ssid.replacingOccurrences(of:" ", with:"")
											self._labelSSID?.text = ssid
										}*/
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
		self._unitType = sender.selectedSegmentIndex
		ud.set(_unitType, forKey: ViewController.KEY_SETTING_UNIT_TYPE)
		
		if(self._carrentAltitude > 0) {
			self._labelNewAlt?.text = self.makeAltitudeString(Int(self._sliderAlt.value))
			self._labelCurrentAlt?.text = String(format: NSLocalizedString("CurrentAltFormat",comment:""), self.makeAltitudeString(self._carrentAltitude) )
		}
		else {
			if(self._unitType ==  ViewController.KEY_UNIT_METER) {
				self._labelNewAlt?.text = "--m"
			}
			else {
				self._labelNewAlt?.text = "--ft"
			}
		}
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

