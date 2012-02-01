package com.impossibilities.avr 
{
	import flash.errors.*;
	import flash.events.*;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	// http://as3htmlparser.sourceforge.net/ - cool class for parsing/displaying HTML

	public class WebSocket extends Socket
	{

		private var response:String;
		private var uiRef:Object;

		public function WebSocket(container:Object, host:String = null, port:uint = 0)
		{
			super();
			uiRef = container;
			configureListeners();
			if (host && port)
			{
				super.connect(host, port);
			}
		}

		private function configureListeners():void
		{
			addEventListener(Event.CLOSE, closeHandler);
			addEventListener(Event.CONNECT, connectHandler);
			addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		}

		private function writeln(str:String):void
		{
			str +=  "\n";
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
			writeln("GET /");
			flush();
			
		}

		private function readResponse(totalBytes):void
		{
			var str:String = readUTF();//readUTFBytes(bytesAvailable);
			trace("START:"+str);
			if(str.length>8000) {
				var re:RegExp = /("friendly_name")( ).*?(value)(=)(".*?")/;
				var res:Object = re.exec(str);
				trace("YOUR AVR NAME:"+res[5]);
			}
			
			
		}

		private function closeHandler(event:Event):void
		{
			trace("closeHandler: " + event);
			trace(response.toString());
		}

		private function connectHandler(event:Event):void
		{
			trace("connectHandler: " + event);
			sendRequest();
		}

		private function ioErrorHandler(event:IOErrorEvent):void
		{
			trace("ioErrorHandler: " + event);
		}

		private function securityErrorHandler(event:SecurityErrorEvent):void
		{
			trace("securityErrorHandler: " + event);
		}

		private function socketDataHandler(event:ProgressEvent):void
		{
			trace("socketDataHandler: " + event);
			readResponse(event.bytesTotal);
		}
	}
}