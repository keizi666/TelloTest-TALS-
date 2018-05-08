//
//  TelloPacket.swift
//  TelloTest
//
//  Created by matsumoto keiji on 2018/05/06.
//  Copyright © 2018 keiziweb. All rights reserved.
//
/*Reference
https://github.com/Kragrathea/TelloPC
https://dl-cdn.ryzerobotics.com/downloads/tello/0228/Tello+SDK+Readme.pdf
https://drive.google.com/file/d/1t12MK-jG4df90gMjD8syPrAZ8VmdqCDA/view
https://gobot.io/blog/2018/04/20/hello-tello-hacking-drones-with-go/

Written article
Tello & C#
https://note.mu/keizi666/n/n68eb25c8aa59

Tello & Java
https://note.mu/keizi666/n/nddef168ffb76

Tello & Swift
https://note.mu/keizi666/n/nc0e3d3cd3a21
*/

import Foundation

class TelloPacket {
	var _size:Int = 0
	var _crc8:Int = 0
	var _typeID:Int = 0
	var _commandID:Int = 0
	var _seqNo:Int = 0
	var _data:[UInt8]? = nil
	var _crc16:Int = 0
	
	var _isCheckCRC:Bool = false

	//Calc CRC ------------------------------------------------------------
	static let poly:Int = 13970
	static let fcstab:[UInt16] = [0, 4489, 8978, 12955, 17956, 22445, 25910, 29887, 35912, 40385, 44890, 48851, 51820, 56293, 59774, 63735, 4225, 264, 13203, 8730, 22181, 18220, 30135, 25662, 40137, 36160, 49115, 44626, 56045, 52068, 63999, 59510, 8450, 12427, 528, 5017, 26406, 30383, 17460, 21949, 44362, 48323, 36440, 40913, 60270, 64231, 51324, 55797, 12675, 8202, 4753, 792, 30631, 26158, 21685, 17724, 48587, 44098, 40665, 36688, 64495, 60006, 55549, 51572, 16900, 21389, 24854, 28831, 1056, 5545, 10034, 14011, 52812, 57285, 60766, 64727, 34920, 39393, 43898, 47859, 21125, 17164, 29079, 24606, 5281, 1320, 14259, 9786, 57037, 53060, 64991, 60502, 39145, 35168, 48123, 43634, 25350, 29327, 16404, 20893, 9506, 13483, 1584, 6073, 61262, 65223, 52316, 56789, 43370, 47331, 35448, 39921, 29575, 25102, 20629, 16668, 13731, 9258, 5809, 1848, 65487, 60998, 56541, 52564, 47595, 43106, 39673, 35696, 33800, 38273, 42778, 46739, 49708, 54181, 57662, 61623, 2112, 6601, 11090, 15067, 20068, 24557, 28022, 31999, 38025, 34048, 47003, 42514, 53933, 49956, 61887, 57398, 6337, 2376, 15315, 10842, 24293, 20332, 32247, 27774, 42250, 46211, 34328, 38801, 58158, 62119, 49212, 53685, 10562, 14539, 2640, 7129, 28518, 32495, 19572, 24061, 46475, 41986, 38553, 34576, 62383, 57894, 53437, 49460, 14787, 10314, 6865, 2904, 32743, 28270, 23797, 19836, 50700, 55173, 58654, 62615, 32808, 37281, 41786, 45747, 19012, 23501, 26966, 30943, 3168, 7657, 12146, 16123, 54925, 50948, 62879, 58390, 37033, 33056, 46011, 41522, 23237, 19276, 31191, 26718, 7393, 3432, 16371, 11898, 59150, 63111, 50204, 54677, 41258, 45219, 33336, 37809, 27462, 31439, 18516, 23005, 11618, 15595, 3696, 8185, 63375, 58886, 54429, 50452, 45483, 40994, 37561, 33584, 31687, 27214, 22741, 18780, 15843, 11370, 7921, 3960 ];

	//uCRC
	static let uCRCTable:[UInt8] = [ 0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65, 157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220, 35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98, 190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255, 70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7, 219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154, 101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36, 248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185, 140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205, 17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80, 175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238, 50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115, 202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139, 87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22, 233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168, 116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53 ]

	
	static let takeOffPacket:[UInt8] = [0xcc, 0x58, 0x00, 0x7c, 0x68,  0x54,  0x00,  0xe4,  0x01,  0xc2,  0x16]
	static let landPacket:[UInt8] = [0xcc, 0x60, 0x00, 0x27, 0x68, 0x55, 0x00, 0xe5, 0x01, 0x00, 0xba, 0xc7]

	static func packetToHexString(packet:[UInt8])->String {
		var hexString:String = "";

		for i in (0 ..< packet.count) {
			hexString.append(String(format:"%02x ",packet[i]))
		}
		return hexString
	}
	
	static func fsc16(_ bytes:[UInt8],_ len:Int,_ poly:Int)->UInt16 {
		var i:Int = 0
		var j:Int = poly
		var poly:Int = len
		var len:Int = j
		while (true) {
			j = len
			if (poly == 0) {
				break
			}
			j = Int(bytes[i])
			len = Int(fcstab[((len ^ j) & 0xFF)] ^ UInt16(len) >> 8)
			i += 1
			poly = poly - 1
		}
		return UInt16(j)
	}

	static func calcCrcToInt(bytes:[UInt8],len:Int)->UInt16	{
		if (len <= 2) {
			return 0
		}
		return fsc16(bytes, len - 2, poly)
	}

	static func calcCrc(bytes:inout[UInt8],len:Int)	{
		let i:UInt16 = calcCrcToInt(bytes: bytes,len: len)
		bytes[(len - 2)] = UInt8((i & 0xFF))
		bytes[(len - 1)] = UInt8((i >> 8 & 0xFF))
	}

	static func uCRC(bytes:[UInt8],len:Int,poly:Int)->UInt8 {
		var j:Int = 0
		var i:Int = poly
		var poly = j
		var len = len

		while (len != 0) {
			j = Int(bytes[poly]) ^ i
			i = j
			if (j < 0) {
				i = j + 256
			}
			i = Int(uCRCTable[i])
			poly += 1
			len = len - 1
		}
		return UInt8(i)
	}

	static func calcUCRC(bytes:inout[UInt8],len:Int) {
		let i:Int = calcUCRCBToInt(bytes: bytes,len: len)
		bytes[(len - 1)] = UInt8(i & 0xFF)
	}

	static func calcUCRCBToInt(bytes:[UInt8],len:Int)->Int {
		if ((bytes.count == 0) || (len <= 2)) {
			return 0
		}
		return Int(uCRC(bytes: bytes, len: len - 1, poly: 119)) & 0xff
	}
	//---------------------------------------------------------------------
	
	//よくある11バイトのパケットを作る　タイプ、コマンド、データなし
	static func build11Packet(type:UInt8,command:UInt16)->[UInt8] {
		//template
		var packet:[UInt8] = [0xcc, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
		//                   start size        crc   type  command     seq         crc       11byte
		let len:UInt8 = UInt8(packet.count)
		packet[ 1] = UInt8(len << 3)
		calcUCRC(bytes: &packet, len: 4)
		
		packet[4] = type
		
		packet[5] = UInt8(command & 0xff)
		packet[6] = UInt8((command >> 8) & 0xff)
		
		calcCrc(bytes: &packet, len: packet.count)
		return packet
	}
	
	//通信開始とその返答（Ackで返答が正しいか確認する）
	static func createConnectReqPacket()->Data {
		let strConnReq = "conn_req:00"
		var byteConnReq = strConnReq.data(using: .utf8)!
		byteConnReq[byteConnReq.count - 2] = 0x96
		byteConnReq[byteConnReq.count - 1] = 0x17

		return byteConnReq
	}

	static func createConnectAckPacket()->Data {
		let strConnAck = "conn_ack:00"
		var byteConnAck = strConnAck.data(using: .utf8)!
		byteConnAck[byteConnAck.count - 2] = 0x96
		byteConnAck[byteConnAck.count - 1] = 0x17
		
		return byteConnAck
	}

	//高度取得コマンドパケットを作る
	static func createGetAltitudePacket()->Data {
		return Data(bytes: build11Packet(type: 0x48,command: 0x1056))
	}

	//高度制限変更コマンドパケットｗ作る
	static func createSetAltitudePacket(altitudeM:Int)->Data {
		//template
		var packet:[UInt8] = [0xcc, 0x00, 0x00, 0x00, 0x68, 0x58, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
		//                    start size        crc   type  command     seq         data        crc       13byte
		
		let len:UInt8 = UInt8(packet.count)
		packet[ 1] = UInt8(len << 3)
		calcUCRC(bytes: &packet, len: 4)

		packet[ 9] = UInt8(altitudeM & 0xff)
		packet[10] = ((UInt8(altitudeM) >> 8) & 0xff)
		
		calcCrc(bytes: &packet, len: packet.count)

		return Data(packet)
		
		/*
		ex:
		30m:cc 68 00 51 68 58 00 00 00 1e 00 a8 5c
		01m:cc 68 00 51 68 58 00 00 00 01 00 f1 4a
		16m:cc 68 00 51 68 58 00 00 00 10 00 b8 c6
		21m:cc 68 00 51 68 58 00 00 00 15 00 00 b8
		*/
	}
	
	//パースしてTelloPacketにする
	static func parsePacket(data:Data)->TelloPacket? {
		let bytes:[UInt8] = [UInt8](data)
		
		let start:Int = Int(bytes[0] & 0xff)
		if(	bytes.count < 11) {
			return nil
		}
		if(start != 0xcc) {
			return nil
		}
		
		let retPacket:TelloPacket = TelloPacket()
	
		retPacket._size = littleEndianToIntWithShift(bytes[1],bytes[2])
		retPacket._crc8 = Int(bytes[3] & 0xff)
	
		retPacket._typeID = Int(bytes[4] & 0xff)
	
		retPacket._commandID =  littleEndianToInt(bytes[5],bytes[6])
		retPacket._seqNo = littleEndianToInt(bytes[7],bytes[8])
	
		let dataSize:Int = retPacket._size - 11
		if(dataSize > 0) {
			retPacket._data = [UInt8](repeating: 0x0,count: dataSize)
			
			for i in (0 ..< dataSize) {
				retPacket._data?[i] = bytes[i + 9]
			}
		}
		retPacket._crc16 = littleEndianToInt(bytes[(bytes.count - 2)],bytes[(bytes.count - 1)])
		
		let crc8Check:Int = calcUCRCBToInt(bytes:bytes, len:4)
		let crc16Check:Int = Int(calcCrcToInt(bytes:bytes, len:bytes.count))
		
		if(crc8Check != retPacket._crc8 || crc16Check != retPacket._crc16) {
			retPacket._isCheckCRC = false;
		}
		else {
			retPacket._isCheckCRC = true;
		}
		return retPacket
	}

	//リトルインディア操作
	static func intToLittleEndianWithShift(_ value:Int,_ src:inout[UInt8]) {
		src[0] = UInt8((value << 3) & 0xff)
		src[1] = UInt8((value >> 8) & 0xff)
	}
	static func intToLittleEndian(_ value:Int,_ src:inout[UInt8]) {
		src[0] = UInt8(value & 0xff)
		src[1] = UInt8((value >> 8) & 0xff)
	}
	static func littleEndianToIntWithShift(_ b0:UInt8,_ b1:UInt8)->Int {
		return  (((Int(b1) & 0xff) << 8) + (Int(b0) >> 3)) & 0xff
	}
	static func littleEndianToInt(_ b0:UInt8,_ b1:UInt8)->Int {
		return  (((Int(b1)) & 0xff) << 8)  + (Int(b0) & 0xff);
	}


}

extension Data {
	var hexString: String {
		return reduce("") {$0 + String(format: "%02x ", $1)}
	}
}
