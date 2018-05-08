//
//  Connection.swift
//  TelloTest
//
//  Created by matsumoto keiji on 2018/05/02.
//  Copyright © 2018年 keiziweb. All rights reserved.
//

import Foundation
import UIKit

class Connection: NSObject, StreamDelegate {
	var ServerAddress: CFString =  NSString(string: "0.0.0.0") //IPアドレスを指定
	var serverPort: UInt32 = 0 //開放するポートを指定
	
	private var inputStream : InputStream!
	private var outputStream: OutputStream!
	
	init(address:String,port:UInt32) {
		ServerAddress =  NSString(string: address)
		serverPort = port
	}
	
	//**
	/* @brief サーバーとの接続を確立する
	*/
	func connect(){
		print("connecting.....")
		
		var readStream : Unmanaged<CFReadStream>?
		var writeStream: Unmanaged<CFWriteStream>?
		
		CFStreamCreatePairWithSocketToHost(nil, self.ServerAddress, self.serverPort, &readStream, &writeStream)
		
		self.inputStream  = readStream!.takeRetainedValue()
		self.outputStream = writeStream!.takeRetainedValue()
		
		self.inputStream.delegate  = self
		self.outputStream.delegate = self
		
		self.inputStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
		self.outputStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
		
		self.inputStream.open()
		self.outputStream.open()
		
		print("connect success!!")
	}
	
	//**
	/* @brief inputStream/outputStreamに何かしらのイベントが起きたら起動してくれる関数
	*        今回の場合では、同期型なのでoutputStreamの時しか起動してくれない
	*/
	func stream(_ stream:Stream, handle eventCode : Stream.Event){
		//print(stream)
	}
	
	//**
	/* @brief サーバーにコマンド文字列を送信する関数
	*/
	func sendCommand(command: String){
		var ccommand = command.data(using: String.Encoding.utf8, allowLossyConversion: false)!
		let text = ccommand.withUnsafeMutableBytes{ bytes in return String(bytesNoCopy: bytes, length: ccommand.count, encoding: String.Encoding.utf8, freeWhenDone: false)!}
		self.outputStream.write(UnsafePointer(text), maxLength: text.utf8.count)
		print("Send: \(command)")
		
		//"end"を受信したら接続切断
		if (String(describing: command) == "end") {
			self.outputStream.close()
			self.outputStream.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
			
			while(!inputStream.hasBytesAvailable){}
			let bufferSize = 1024
			var buffer = Array<UInt8>(repeating: 0, count: bufferSize)
			let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
			if (bytesRead >= 0) {
				let read = String(bytes: buffer, encoding: String.Encoding.utf8)!
				print("Receive: \(read)")
			}
			self.inputStream.close()
			self.inputStream.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
		}
	}
	
}
