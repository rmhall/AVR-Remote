/*
	The MIT License
	 
	Copyright (c) 2012 Robert M. Hall, II, Inc. dba Feasible Impossibilities - http://www.impossibilities.com/
	 
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	 
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	 
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
*/

package com.impossibilities.avr 
{

	import flash.errors.*;
	import flash.events.*;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	import flash.net.DatagramSocket;

	public class AVRupnp extends DatagramSocket
	{

		private var response:String;
		private var uiRef:Object;
		private var timeoutValue:Number = 5000;

		public function AVRupnp(container:Object, host:String=null, port:uint=0)
		{
			super();
			uiRef = container;
			configureListeners();
			if ((host && port))
			{
				timeout = timeoutValue;
				super.connect(host,port);
			}
		}

		private function socketTimeout():void
		{
			trace("Socket Connection Timeout");
			uiRef.connectionTimeout();
			close();
		}

		private function configureListeners():void
		{
			addEventListener(Event.CLOSE,closeHandler);
			addEventListener(Event.CONNECT,connectHandler);
			addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR,securityErrorHandler);
			addEventListener(ProgressEvent.SOCKET_DATA,socketDataHandler);
		}

		private function writeln(str:String):void
		{
			//str +=  "\n";
			try
			{
				writeUTFBytes(str);
			}
			catch (e:IOError)
			{
				trace(e);
			}
		}

		private function sendRequest():void
		{
			response = "";
			
			sendCommand("!1PWRQSTN");
			flush();
			
			trace("FLUSHED");
			
		}

		private function traceBytes():String
		{
			var str:String = "";
			var lit:String = "";
			for (var i = 0; i < bytes.length; i++)
			{
				lit = lit +=  bytes[i] + ".";
				if (bytes[i] != 0)
				{
					str +=  String.fromCharCode(bytes[i]);
				}
			}
			return "LIT: " + lit + "\nSTR: " + str;
		}

		private function parseResponseBytes():String
		{
			var str:String = "";
			for (var i = 16; i <= 23; i++)
			{
				if (bytes[i] != 0)
				{
					str +=  String.fromCharCode(bytes[i]);
				}
			}
			trace(("ResponseCODE: " + str));
			trace((("RESPONSE:\n" + traceBytes()) + "******"));
			return str;
		}

		var bytes:ByteArray = new ByteArray  ;
		private function readResponse(totalBytes):void
		{
			//var str:String = readUTFBytes(this.bytesAvailable);
			//var str:String = readMultiByte(bytesAvailable, "iso-8859-3");
			readBytes(bytes,0,0);
			//trace(bytes.length);
			//trace(bytes.objectEncoding);
			var str:String = "";
			var lit:String = "";
			// ISCP!1NTM01:16/07:45

			//response = str;
			//trace(str, totalBytes);
			var curBytes:String = parseResponseBytes();
			trace(("CURBYTES: " + curBytes.substr(0,5)));
			if (curBytes.substr(0,5) == "!1MVL")
			{
				//avrVolume=curBytes.substr(6,2);
				var hexVal = "0x" + curBytes.substr(5,2);
				trace( "HEX VOLUME:" + hexVal, "HEX2DEC: " + hex2dec(hexVal) );
				uiRef.setavrVolume(hex2dec(hexVal));
			}
			var avrPower:Boolean;
			if (curBytes.substr(0,5) == "!1PWR")
			{
				var powerStatus = curBytes.substr(5,2);
				if ((powerStatus == "00"))
				{
					avrPower = false;
				}
				if ((powerStatus == "01"))
				{
					avrPower = true;
				}
				uiRef.setavrPower(avrPower);
			}
		}

		public function dec2hex(dec:String):String
		{
			var hex:String = "";//"0x";
			var bytes:Array = dec.split(" ");
			for (var i:int = 0; i < bytes.length; i++)
			{
				hex +=  d2h(int(bytes[i]));
			}
			return hex;
		}

		private function d2h(d:int):String
		{
			var c:Array = ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'];
			if ((d > 255))
			{
				d = 255;
			}
			var l:int = d / 16;
			var r:int = d % 16;
			return c[l] + c[r];
		}

		public function hex2dec(hex:String):String
		{
			var bytes:Array = [];
			while (hex.length > 2)
			{
				var byte:String = hex.substr(-2);
				hex = hex.substr(0,hex.length - 2);
				bytes.splice(0,0,int(("0x" + byte)));
			}
			return bytes.join(".");
		}

		public function padString(str:String,len:Number,pad:String):String
		{
			var newStr:String = "";
			if (str.length < len)
			{
				newStr = pad + str;
			}
			return newStr;
		}


		// EOF, CR, LF
		public function sendCommand(cmd:String):void
		{
			var avrCommand:String = cmd;
			var avrLength:Number = avrCommand.length;
			avrLength++;
			var avrTotal:Number = avrLength + 16;
			var avrCode:String = String.fromCharCode(avrLength);
			var avrRequest:String = "ISCP\x00\x00\x00\x10\x00\x00\x00" + avrCode + "\x01\x00\x00\x00" + avrCommand + "\x0D\x0A";
			trace(((("SendCommand: " + cmd) + " - ") + hex2dec(avrRequest)));
			writeln(avrRequest);
		}



		private function closeHandler(event:Event):void
		{
			trace(("closeHandler: " + event));
			trace(response.toString());
			uiRef.setIconStatus(false);
		}

		private function connectHandler(event:Event):void
		{
			trace(("connectHandler: " + event));
			uiRef.setIconStatus(true);

		}

		private function ioErrorHandler(event:IOErrorEvent):void
		{
			trace(("ioErrorHandler: " + event));
			uiRef.setIconStatus(false);
			if (event.errorID == 2031)
			{
				trace("Socket failed to connect");
			}
		}

		private function securityErrorHandler(event:SecurityErrorEvent):void
		{
			trace(("securityErrorHandler: " + event));
			uiRef.setIconStatus(false);
		}

		private function socketDataHandler(event:ProgressEvent):void
		{
			//trace("socketDataHandler: " + event);
			readResponse(event.bytesTotal);
		}
	}//
}