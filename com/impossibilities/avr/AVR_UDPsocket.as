package com.impossibilities.avr 
{
	import flash.display.Sprite;
	import flash.events.DatagramSocketDataEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.net.DatagramSocket;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	public class AVR_UDPsocket extends Sprite
	{
		private var datagramSocket:DatagramSocket = new DatagramSocket();

		private var localIP:TextField;
		private var localPort:TextField;
		private var logField:TextField;
		private var targetIP:TextField;
		private var targetPort:TextField;
		private var message:TextField;
		
		private var uiRef:Object;

		public function AVR_UDPsocket(container:Object)
		{
			uiRef = container;
			setupUI();
		}

		private function bind( event:Event ):void
		{
			if (datagramSocket.bound)
			{
				datagramSocket.close();
				datagramSocket = new DatagramSocket();

			}
			datagramSocket.bind();
			
			datagramSocket.addEventListener( DatagramSocketDataEvent.DATA, dataReceived );
			
			datagramSocket.receive();
			
			log( "Bound to: " + datagramSocket.localAddress + ":" + datagramSocket.localPort );
		}

		private function dataReceived( event:DatagramSocketDataEvent ):void
		{
			//Read the data from the datagram
			log("Received from " + event.srcAddress + ": " + event.srcPort+ " :: "+
			                event.data.readUTFBytes( event.data.bytesAvailable ) );
		}

		private function send( event:Event ):void
		{
			//Create a message in a ByteArray
			var data:ByteArray = new ByteArray();
			data.writeUTFBytes( message.text );

			//Send a datagram to the target
			try
			{
				datagramSocket.send( data, 0, 0, targetIP.text, 61028);
				log( "Sent message to " + targetIP.text + ":" + targetPort.text );
			}
			catch (error:Error)
			{
				log( error.message );
			}
		}

		private function log( text:String ):void
		{
			logField.appendText( text + "\n" );
			logField.scrollV = logField.maxScrollV;
			trace( text );
		}
		
		private function setupUI():void
		{
			
			createTextButton( 250, 135, "Bind", bind );
			createTextButton( 300, 135, "Send", send );
			
			logField = createTextField( 10, 160, "Log:", "", false, 200 );
		}

		

	}
}