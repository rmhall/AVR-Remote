package com.impossibilities.avr 
{

	import flash.errors.*;
	import flash.events.*;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;

	public class CustomSocket extends Socket
	{

		private var response:String;
		private var uiRef:Object;
		private var timeoutValue:Number = 5000;

		public function CustomSocket(container:Object, host:String=null, port:uint=0)
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
			//writeln("GET /");
			//sendCommand("!1PWR00");//ON
			// flush();
			sendCommand("!1PWRQSTN");
			flush();
			//setTimeout(sendCommand, 150, "!1SLIQSTN");
			//setTimeout(flush, 175);
			/*
			trace(dec2hex("10"));
			trace("PAD: "+padString(dec2hex("10"),2,"0"));
			setVolume("50");
			flush();
			
			*/
			trace("FLUSHED");
			//sendCommand("!1PWR00"); //OFF
			// POWEROFF RESULT: 73.83.67.80 - 0.0.0.16.0.0.0.10.1.0.0.0 - 33.49.80.87.82.48.48.26.13.10
			// POWERON RESULT: 73.83.67.80 - 0.0.0.16.0.0.0.10.1.0.0.0 - 33.49.80.87.82.48.49.26.13.10

			// VOLUME RESULT: 73.83.67.80 - 0.0.0.16.0.0.0.10.1.0.0.0 - 33.49.77.86.76 - 50.65 - 26.13.10
			// VOLUME RESULT: 73.83.67.80 - 0.0.0.16.0.0.0.10.1.0.0.0 - 33.49.77.86.76 - 51.50 - 26.13.10
			//flush();
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
			var i:uint = 16;
			for (i = 16; i <= 23; i++)
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

		private function allBytes():String
		{
			var str:String = "";
			var i:uint = 21;
			for (i = 21; i < bytes.length; i++)
			{
				if (bytes[i] >= 43 && bytes[i] <= 126)
				{
					str +=  String.fromCharCode(bytes[i]);
				}
			}
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
			var curBytesShort:String = curBytes.substr(0,5);
			var curBytesShortVal:String = curBytes.substr(5,2);
			trace(("CURBYTES: " + curBytesShort)+"\n");
			if (curBytesShort == "!1MVL")
			{
				//avrVolume=curBytes.substr(6,2);
				var hexVal = "0x" + curBytes.substr(5,2);
				trace( "HEX VOLUME:" + hexVal, "HEX2DEC: " + hex2dec(hexVal) );
				uiRef.setavrVolume(hex2dec(hexVal));
			}
			var avrPower:Boolean;
			if (curBytesShort == "!1PWR")
			{
				var powerStatus = curBytesShortVal;
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

			if (curBytesShort == "!1SLI")
			{
				var avrSLI = curBytesShortVal;

				uiRef.setavrSLI(avrSLI);
			}

			if (curBytesShort == "!1AMT")
			{
				var avrMUTE = curBytesShortVal;

				uiRef.setavrMUTE(avrMUTE);
			}
			
			var dispInfo_arr:Array;
			
			if (curBytesShort == "!1IFA")
			{
				//var avrIFA = curBytes.substr(5,2);
				var avrIFA:String = allBytes();
				
				
				if(avrIFA != "N/A") {
					trace("IFA: "+avrIFA);
				 dispInfo_arr = avrIFA.split(",");
				trace(dispInfo_arr[4], dispInfo_arr[5]);
				uiRef.modeTxt.text = dispInfo_arr[4] + " " + dispInfo_arr[5];
				/* 
				0 = INPPUT
				1 = IN AudioMode
				2 = IN sampling
				3 = IN Channels
				4 = OUT Listening Mode
				5 = OUT
				HDMI3,DolbyD,48kHz,5.1ch,DolbyPLIIxMovie,7.1ch,
				*/
				}
			}
			
			if (curBytesShort == "!1IFV")
			{
				//var avrIFA = curBytes.substr(5,2);
				var avrIFV:String = allBytes();
				
				if(avrIFV != "") {
				trace("IFV: "+avrIFV);
				 dispInfo_arr = avrIFV.split(",");
				trace(dispInfo_arr[4], dispInfo_arr[5]);
				//uiRef.modeTxt.text = dispInfo_arr[4] + " " + dispInfo_arr[5];
				/* 
				HDMI3,1920x1080i60Hz,YCbCr,24bit,HDMI,UNKNOWN,None,24bit,Custom,
				*/
			}

			}
		}

		private function dec2hex(dec:String):String
		{
			var hex:String = "";//"0x";
			var bytes:Array = dec.split(" ");
			var i:uint = 0;
			for (i = 0; i < bytes.length; i++)
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

		public function setVolume(vol:String):void
		{

			//var avrVolume:String = padString(dec2hex(vol),2,"0");
			var avrVolume = dec2hex(vol);
			trace(("avrVolume:" + avrVolume));
			var avrCommand:String = "!1MVL" + avrVolume;
			var avrLength:Number = avrCommand.length;
			avrLength++;
			var avrTotal:Number = avrLength + 16;
			var avrCode:String = String.fromCharCode(avrLength);
			var avrRequest:String = "ISCP\x00\x00\x00\x10\x00\x00\x00" + avrCode + "\x01\x00\x00\x00" + avrCommand + "\x0D\x0A";
			trace(("SETVOLUME: " + hex2dec(avrRequest)));
			writeln(avrRequest);
		}


		// EOF, CR, LF
		//private var cmdQueue_arr:Array = new Array();
		//private var avrRequestQueue_arr:Array = new Array();

		// http://nsdevaraj.wordpress.com/2008/11/04/execute-commands-on-queue/
		// http://efnx.com/as3-dolatertodo-function-queue/
		// http://lab.polygonal.de/2007/05/23/data-structures-example-the-queue-class/

		public function sendCommand(cmd:String):void
		{
			//cmdQueue_arr.push(cmd);

			var avrCommand:String = cmd;
			var avrLength:Number = avrCommand.length;
			avrLength++;
			var avrTotal:Number = avrLength + 16;
			var avrCode:String = String.fromCharCode(avrLength);
			var avrRequest:String = "ISCP\x00\x00\x00\x10\x00\x00\x00" + avrCode + "\x01\x00\x00\x00" + avrCommand + "\x0D\x0A";
			trace(((("\nSendCommand: " + cmd) + " - ") + hex2dec(avrRequest)));
			//avrRequestQueue_arr.push(avrRequest);
			writeln(avrRequest);
		}




		/*
		  $vol=str_pad(dechex($command), 2, '0', STR_PAD_LEFT);
		  $command="!1MVL$vol";
		 }
		// Calculate header and datapacket lengths
		$length=strlen($command); 
		$length=$length+1;
		$total=$length+16;
		$code=chr($length);
		// total eiscp packet to send 
		$line="ISCP\x00\x00\x00\x10\x00\x00\x00$code\x01\x00\x00\x00".$command."\x0D";
		
		!1PWR00,Poweroff
		!1PWR01,Poweron
		
		Volume:
		output="ISCP\x00\x00\x00\x10\x00\x00\x00$code\x01\x00\x00\x00".$command."\x0D";
		
		ISCP
		
		*/

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

	}
}