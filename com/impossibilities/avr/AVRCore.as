package com.impossibilities.avr 
{
	import flash.display.Sprite;
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;
	import flash.net.DatagramSocket;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display.StageOrientation;
	import flash.utils.setTimeout;
	
	// import AVR_UDPsocket;

	import flash.filesystem.*;

	import flash.display.MovieClip;
	import flash.media.StageWebView;
	import flash.geom.Rectangle;

	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormatAlign;

	import com.impossibilities.avr.DelayedFunctionQueue;
	import com.impossibilities.avr.CustomSocket;

	// Tweening
	import com.greensock.*;
	import com.greensock.plugins.*;
	import com.greensock.easing.*;
	import flash.text.TextField;

	TweenPlugin.activate([TintPlugin]);
	TweenPlugin.activate([ColorTransformPlugin]);
	TweenPlugin.activate([GlowFilterPlugin]);


	public class AVRCore extends Sprite
	{

		private var avrINIT:Boolean = false;
		private var avrJustOpened:Boolean = true;
		private var avrVolume:Number;
		private var avrPower:Boolean = false;
		private var appState:String = "MAIN";
		private var appSubState:String = "";
		private var avrSLI:String = "";
		
		private var avrSLI_names_arr:Array = new Array( "cableButt","appletvButt","xboxButt", "ps3Butt","tunerButt");
		private var avrSLI_vals_arr:Array = new Array("01","05","02","10","24");
		
		private var avrMUTE:Boolean=false;

		private var avrAVR:String;
		private var avrName:String;
		private var avrIP:String;
		private var avrPORT:Number;
		private var avrMAC:String;
		private var avrUPNP:Boolean;
		private var ActivateCalled:Number = 1;
		
		private var cmdQUEUE:CommandQueue = new CommandQueue();


		private var webView:StageWebView = new StageWebView();

		private var socket:CustomSocket = new CustomSocket(this); //this,"192.168.1.21", 60128
		
		//var udpSocket:AVRupnp;

		private var textLoader:URLLoader = new URLLoader  ;
		private var textReq:URLRequest;// = new URLRequest("http://192.168.1.21");

		public var prefsFile:File;// The preferences prefsFile
		[Bindable]
		public var prefsXML:XML;// The XML data
		public var stream:FileStream;// The FileStream object used to read and write prefsFile data.
		
		private var originalFrameRate:uint = stage.frameRate; 
		private var standbyFrameRate:uint = 4; 


		public function AVRCore()
		{
			stage.align = StageAlign.TOP_LEFT; 
			stage.scaleMode = StageScaleMode.NO_SCALE;

			appComplete();

			settingsButtHigh.visible = false;

			loader_mc.visible = true;

			settingsContent.closeButt.visible = false;

			addEventListener(Event.ENTER_FRAME,rotateLoader);


			textLoader.addEventListener(Event.COMPLETE,textLoadComplete);
			// need to add other listeners for textLoader - and maybe move from beginning to after saving the prefs, do the autosearch then;

			powerButt.addEventListener(MouseEvent.MOUSE_DOWN,powerHandler);
			powerButt.addEventListener(MouseEvent.MOUSE_UP,powerHandlerUp);
			
			muteButt.addEventListener(MouseEvent.MOUSE_DOWN,muteHandler);
			muteButt.addEventListener(MouseEvent.MOUSE_UP,muteHandlerUp);


			volumeUp.addEventListener(MouseEvent.MOUSE_DOWN, volumeHandler);
			volumeDown.addEventListener(MouseEvent.MOUSE_DOWN,volumeHandler);
			
			volumeUp.addEventListener(MouseEvent.MOUSE_UP, volumeHandlerUp);
			volumeDown.addEventListener(MouseEvent.MOUSE_UP,volumeHandlerUp);
			
			
			cableButt.addEventListener(MouseEvent.MOUSE_DOWN,sourceHandler);
			appletvButt.addEventListener(MouseEvent.MOUSE_DOWN,sourceHandler);
			xboxButt.addEventListener(MouseEvent.MOUSE_DOWN,sourceHandler);
			ps3Butt.addEventListener(MouseEvent.MOUSE_DOWN,sourceHandler);
			tunerButt.addEventListener(MouseEvent.MOUSE_DOWN,sourceHandler);
			
			cableButt.addEventListener(MouseEvent.MOUSE_UP,sourceHandlerUp);
			appletvButt.addEventListener(MouseEvent.MOUSE_UP,sourceHandlerUp);
			xboxButt.addEventListener(MouseEvent.MOUSE_UP,sourceHandlerUp);
			ps3Butt.addEventListener(MouseEvent.MOUSE_UP,sourceHandlerUp);
			tunerButt.addEventListener(MouseEvent.MOUSE_UP,sourceHandlerUp);
			
			stage.addEventListener ( Event.ACTIVATE, onActivate ); 
			stage.addEventListener ( Event.DEACTIVATE, onDeactivate ); 

			titleHeader.infoButt.addEventListener(MouseEvent.CLICK,infoHandler);
			aboutContent.homeButt.addEventListener(MouseEvent.CLICK,infoHandler);

			settingsButt.addEventListener(MouseEvent.CLICK,panelHandler);
			settingsButtHigh.addEventListener(MouseEvent.CLICK,panelHandler);

			receiverButt.addEventListener(MouseEvent.CLICK,panelHandler);
			receiverButtHigh.addEventListener(MouseEvent.CLICK,panelHandler);

			settingsContent.saveButt.addEventListener(MouseEvent.CLICK,saveHandler);
			settingsContent.openButt.addEventListener(MouseEvent.CLICK,StageWebViewExample);

			settingsContent.toggleON.addEventListener(MouseEvent.CLICK, autoToggleHandler);
			settingsContent.toggleOFF.addEventListener(MouseEvent.CLICK,autoToggleHandler);

			statusIcon.addEventListener(MouseEvent.CLICK, statusClickHandler);
			

			stage.addEventListener(StageOrientationEvent.ORIENTATION_CHANGE, onOrientationChange); 
 		    stage.addEventListener(StageOrientationEvent.ORIENTATION_CHANGING, onOrientationChanging);

			textHandlerInit();

			TweenLite.to(splashImage,.75,{alpha: 0, scaleX: 0, scaleY:0});
			TweenLite.to(rcvrTxt_mc,.5,{colorTransform:{tint:0xffffff,tintAmount:1}});

			//avrVolume = parseInt(volumeTxt.text);
		}
		
		function onActivate ( e:Event ):void 
		{ 
		trace("ACTIVATE CALLED");
			
				if(avrINIT) {
				// restore original frame rate 
				stage.frameRate = originalFrameRate; 
				trace("GAINED FOCUS: REACTIVATING - Checking network socket...");
				
					if(socket.connected) {
						trace("Good to go! Still connected. Go about your biz.");
					} else {
						trace("Poop on a stick, socket dropped - re-connect socket folks");
						avrINIT=false;
						initComm();
					}
				} else {
					
					if(!socket.connected) {
						trace("CALLING INITCOMM");
						initComm();
					}
				}
		
			//ActivateCalled++;
		} 
		  
		function onDeactivate ( e:Event ):void 
		{ 
			// set frame rate to 0 
			trace("LOST FOCUS: Closing Sockets saving state");
			stage.frameRate = standbyFrameRate; 
			socket.close();
		}

		private function initComm():void
		{
			if (! avrINIT)
			{
				var netWorkType:String = detectNetworkType();

				if (netWorkType)
				{
					avrINIT = true;

					if(ActivateCalled ==1) {
						textReq = new URLRequest("http://"+avrIP);
						textLoader.load(textReq);
						ActivateCalled++;
					}
					
					socket = new CustomSocket(this,avrIP,avrPORT);
					cmdQUEUE.add(socket.sendCommand, "!1MVLQSTN");
					cmdQUEUE.add(socket.sendCommand, "!1PWRQSTN");
					cmdQUEUE.add(socket.sendCommand, "!1SLIQSTN");
					cmdQUEUE.add(socket.sendCommand, "!1AMTQSTN");
					cmdQUEUE.add(socket.sendCommand, "!1IFAQSTN");
					cmdQUEUE.add(socket.sendCommand, "!1IFVQSTN");
					/*
					socket.sendCommand("!1PWRQSTN");
					socket.sendCommand("!1MVLQSTN");
					socket.sendCommand("!1SLIQSTN");
					socket.sendCommand("!1AMTQSTN");
					*/
					
				}
			}

		}
		
		private function onOrientationChanging(event:StageOrientationEvent):void {
			event.preventDefault();
			switch (event.afterOrientation) { 
					case StageOrientation.DEFAULT: 
					stage.setOrientation(StageOrientation.DEFAULT); 
						// re-orient display objects based on 
						// the default (right-side up) orientation. 
						break; 
					case StageOrientation.ROTATED_RIGHT: 
						// Re-orient display objects based on 
						// right-hand orientation. 
						break; 
					case StageOrientation.ROTATED_LEFT: 
						// Re-orient display objects based on 
						// left-hand orientation. 
						break; 
					case StageOrientation.UPSIDE_DOWN: 
					stage.setOrientation(StageOrientation.UPSIDE_DOWN); 
						// Re-orient display objects based on 
						// upside-down orientation. 
						break; 
		}
		}
		
		private function onOrientationChange(event:StageOrientationEvent):void 
			{ 
				switch (event.afterOrientation) { 
					case StageOrientation.DEFAULT: 
						// re-orient display objects based on 
						// the default (right-side up) orientation. 
						break; 
					case StageOrientation.ROTATED_RIGHT: 
						// Re-orient display objects based on 
						// right-hand orientation. 
						break; 
					case StageOrientation.ROTATED_LEFT: 
						// Re-orient display objects based on 
						// left-hand orientation. 
						break; 
					case StageOrientation.UPSIDE_DOWN: 
						// Re-orient display objects based on 
						// upside-down orientation. 
						break; 
			}
			}
			
		
		
		private function networkState(event:Event):void
		{
			trace(event);
		}

		private function detectNetworkType():String
		{
			
			/*
			
			if(DatagramSocket.isSupported) {
				trace("UDP Socket Support: "+DatagramSocket.isSupported);
				// initiate autodiscovery and config
				// Bummed no broadcast address support even for desktop currently :(
				// udpSocket = new AVR_UDPsocket(this);
			}
			*/
			
			var returnVal:String;
			if (NetworkInfo.isSupported)
			{

				var interfaces:Vector.<NetworkInterface >  = NetworkInfo.networkInfo.findInterfaces();

				addEventListener(Event.NETWORK_CHANGE, networkState);

				for (var i:uint = 0; i < interfaces.length; i++)
				{
					trace(interfaces[i].name);

					if (interfaces[i].name.toLowerCase() == "wifi" && interfaces[i].active)
					{

						trace("WiFi connection enabled");
						returnVal = "WIFI";

						break;

					}
					else if (interfaces[i].name.toLowerCase() == "mobile" && interfaces[i].active)
					{

						trace("Mobile data connection enabled");
						returnVal = "MOBILE";

						break;

					}
					else if (interfaces[i].name.toLowerCase().substr(0,2) == "en" && interfaces[i].active)
					{
						// for desktop
						trace("Local Ethernet data connection enabled");
						returnVal = "ETHER";

						break;

					}

				}
			}
			else
			{
				returnVal = "NOGO";
			}
			return returnVal;
		}


		private function saveHandler(event:MouseEvent):void
		{

			prefsXML.AVR = settingsContent.avrTxt.text;
			prefsXML.AVR_NAME = settingsContent.avrNAMETxt.text;
			prefsXML.AVR_IP = settingsContent.avrIPTxt.text;
			prefsXML.AVR_PORT = settingsContent.avrPORTTxt.text;
			prefsXML.AVR_MAC = settingsContent.avrMACTxt.text;
			//prefsXML.AVR_UPNP = settingsContent.avrUPNP.toString();

			writeXMLData();
			receiverButt.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		}


		private function rotateLoader(event:Event)
		{
			loader_mc.rotation +=  30;
		}

		private function textLoadComplete(event:Event):void
		{
			var re:RegExp = /("friendly_name")( ).*?(value)(=)(".*?")/;
			var res:Object = re.exec(textLoader.data);
			trace(("YOUR AVR NAME:" + res[5]));
			titleTxt.text = "ONKYO " + res[5];
			removeEventListener(Event.ENTER_FRAME,rotateLoader);
			loader_mc.visible = false;
		}

		public function setIconStatus(bool:Boolean)
		{
			switch (bool)
			{
				case true :
					statusIcon.gotoAndStop(3);
					removeEventListener(Event.ENTER_FRAME,rotateLoader);
					loader_mc.visible = false;
					break;
				case false :
					statusIcon.gotoAndStop(2);
					settingsButt.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
					break;
			}
		}

		public function setavrVolume(val:Number):void
		{
			avrVolume = val;
			trace(("Current Volume:" + avrVolume));
			volumeTxt.text = "-" + avrVolume.toString() + ".0 dBm";
			var percent = Math.round(((val * 100) / 82)) / 100;
			trace(percent);
			volumeBar.scaleX = percent;
		}

		public function setavrPower(bool:Boolean):void
		{
			avrPower = bool;
			trace(("Current Volume:" + avrVolume));
			if ((avrPower == true))
			{
				TweenLite.to(powerButt.powerIcon,.5,{colorTransform:{tint:0x0D9FFF,tintAmount:.75}});
			}
			else
			{
				TweenLite.to(powerButt.powerIcon,.5,{colorTransform:{tint:0x00000,tintAmount:0}});
			}
		}
		
		public function setavrMUTE(val:String):void {
			switch(val) {
				case "01":
				avrMUTE=true;
				TweenMax.to(muteButt, .5, {glowFilter:{color:0x0D9FFF, alpha:.65, blurX:15, blurY:15, inner:true, strength:2}});
				break;
				case "00":
				avrMUTE=false;
				TweenMax.to(muteButt, .5, {glowFilter:{color:0x00000, alpha:0, blurX:0, blurY:0, inner:true, strength:1, remove: true}});
				break;
			}
		}
		

		private function statusClickHandler(event:MouseEvent):void
		{
			trace("statusIcon: "+statusIcon.currentFrame);
			switch (statusIcon.currentFrame)
			{
				case 1 :
					// Not finished connecting - hang on there fancypants
					break;
				case 2 :
					// Borked socket - failure - ask to retry, or pop open settings.
					avrINIT = false;
					initComm();
					break;
				case 3 :
					// Connected! Nothing to do here but golf clap
					break;
			}
		}

		private function autoToggleHandler(event:MouseEvent):void
		{
			switch (event.currentTarget.name)
			{
				case "toggleON" :
					settingsContent.toggleON.visible = false;
					settingsContent.toggleOFF.visible = true;
					break;
				case "toggleOFF" :
					settingsContent.toggleON.visible = true;
					settingsContent.toggleOFF.visible = false;
					break;
			}
		}

		private function panelHandler(event:MouseEvent):void
		{
			var xPos:Number = 3;
			trace("APPSTATE: "+event.currentTarget.name);
			switch (event.currentTarget.name.substr(0,8))
			{
				case "settings" :
					appState = "SETTINGS";
					settingsButtHigh.visible = true;
					receiverButtHigh.visible = false;
					TweenLite.to(rcvrTxt_mc,.5,{colorTransform:{tint:0x000000,tintAmount:0}});
					TweenLite.to(settingsTxt_mc,.5,{colorTransform:{tint:0xffffff,tintAmount:1}});
					xPos = 264;
					break;
				case "receiver" :
					appState = "MAIN";
					settingsButtHigh.visible = false;
					receiverButtHigh.visible = true;
					TweenLite.to(rcvrTxt_mc,.5,{colorTransform:{tint:0xffffff,tintAmount:1}});
					TweenLite.to(settingsTxt_mc,.5,{colorTransform:{tint:0x000000,tintAmount:0}});
					xPos = 3;
					break;
			}
			TweenLite.to(navpanelButt, .25, {x: xPos});
			changeState();

		}

		private function changeState():void
		{

			switch (appState)
			{
				case "SETTINGS" :
					TweenLite.to(settingsContent, .25, {x: 0 });
					aboutContent.x = stage.stageWidth + 1;
					break;
				case "MAIN" :
					TweenLite.to(settingsContent, .25, {x: (stage.stageWidth+1) });
					TweenLite.to(aboutContent, .25, {x: (stage.stageWidth+1) });
					break;
				case "ABOUT" :
					break;
			}
			trace("APPSTATE: "+appState);
		}

		private function infoHandler(event:MouseEvent):void
		{
			trace(event.currentTarget.name);
			switch (event.currentTarget.name)
			{
				case "infoButt" :
					appState = "ABOUT";
					TweenLite.to(titleHeader, .25, {x:(stage.stageWidth*-1)});
					TweenLite.to(aboutContent, .25, {x: 0});
					aboutContent.wiffy.gotoAndPlay(2);
					break;
				case "homeButt" :
					appState = "MAIN";
					TweenLite.to(titleHeader, .25, {x:0});
					TweenLite.to(aboutContent, .25, {x: stage.stageWidth+1});
					aboutContent.wiffy.gotoAndStop(1);
					break;
			}

		}
		
/*		
"00"sets VIDEO1    VCR/DVR
"01"sets VIDEO2    CBL/SAT
"02"sets VIDEO3    GAME/TV    GAME
"03"sets VIDEO4    AUX1(AUX)
"04"sets VIDEO5    AUX2
"05"sets VIDEO6    PC
"06"sets VIDEO7
"07"Hidden1
"08"Hidden2
"09"Hidden3
"10"sets DVD          BD/DVD
"20"sets TAPE(1)    TV/TAPE
"21"sets TAPE2
"22"sets PHONO
"23"sets CD    TV/CD
"24"sets FM
"25"sets AM
“26”sets TUNER
"27"sets MUSIC SERVER    P4S   DLNA*2
"28"sets INTERNET RADIO           iRadio Favorite*3
"29"sets USB/USB(Front)
"2A"sets USB(Rear)
"2B"sets NETWORK                      NET
"2C"sets USB(toggle)
"40"sets Universal PORT
"30"sets MULTI CH
"31"sets XM*1
"32"sets SIRIUS*1
"UP"sets Selector Position Wrap-Around Up
"DOWN"sets Selector Position Wrap-Around Down
"QSTN"gets The Selector Position
*/

		/*
		private function avrSLIDisp():void {
			switch (avrSLI)
			{
				case "01":
					cableButt
					break;
				case "02":
					xboxButt
					break;
				case "05":		
					appletvButt
					break;
				case "10":
					ps3Butt
					break;
				case "24":
					tunerButt
					break;
			}
		}
		*/
		
		
		
		public function setavrSLI(val:String):void {
			avrSLI = val;
			var i:Number = 0;
			var item:Object;
			for(i=0; i<avrSLI_names_arr.length; i++) {
				//trace(avrSLI_names_arr[i]);
				item = getChildByName(avrSLI_names_arr[i]);
				
				TweenMax.to(item, .5, {glowFilter:{color:0x00000, alpha:0, blurX:0, blurY:0, inner:true, strength:1, remove: true}});

				if(avrSLI_vals_arr[i] == val) {
					TweenMax.to(item, .5, {glowFilter:{color:0x0D9FFF, alpha:.65, blurX:15, blurY:15, inner:true, strength:2}});
				}
			}
		}
		private function sourceHandlerUp(event:MouseEvent):void
		{
			event.currentTarget.gotoAndStop(1);
		}
		
		private function sourceHandler(event:MouseEvent):void
		{
			var sli:String="!1SLI";
			event.currentTarget.gotoAndStop(2);
			switch (event.currentTarget.name)
			{
				case "cableButt" :
				sli+="01";
				break;
				case "xboxButt" :
				sli+="02";
				break;
				case "appletvButt" :
				sli+="05";		
				break;
				case "ps3Butt" :
				sli+="10";
				break;
				case "tunerButt" :
				sli+="24";
				break;
			}
			trace("INPUT SELECTOR: "+event.currentTarget.name, sli);
				cmdQUEUE.add(socket.sendCommand, sli);
				//socket.sendCommand(sli);
		}
		
		private function muteHandlerUp(event:MouseEvent):void
		{
			event.currentTarget.gotoAndStop(1);
		}

		private function muteHandler(event:MouseEvent):void
		{
			event.currentTarget.gotoAndStop(2);			
			switch (avrMUTE)
			{
				case true :
					// turn it off if it was true
					//socket.sendCommand("!1AMT00");
					cmdQUEUE.add(socket.sendCommand, "!1AMT00");
					break;
				case false :
					// turn it on if it was false
					//socket.sendCommand("!1AMT01");
					cmdQUEUE.add(socket.sendCommand, "!1AMT01");
					break;
			}

		}
		
		
		private function powerHandlerUp(event:MouseEvent):void
		{
			event.currentTarget.gotoAndStop(1);
		}

		private function powerHandler(event:MouseEvent):void
		{
			event.currentTarget.gotoAndStop(2);
			switch (avrPower)
			{
				case true :
					// turn it off if it was true
					//socket.sendCommand("!1PWR00");
					cmdQUEUE.add(socket.sendCommand, "!1PWR00");
					break;
				case false :
					// turn it on if it was false
					//socket.sendCommand("!1PWR01");
					cmdQUEUE.add(socket.sendCommand, "!1PWR01");
					break;
			}

		}

		private function volumeHandlerUp(event:MouseEvent):void
		{
			event.currentTarget.gotoAndStop(1);
		}

		private function volumeHandler(event:MouseEvent):void
		{
			event.currentTarget.gotoAndStop(2);
			switch(event.currentTarget.name) {
				case "volumeUp":
				avrVolume++;
				break;
				case "volumeDown":
				avrVolume--;
				break;
			}
			
			checkVolume();
			cmdQUEUE.add(socket.setVolume, avrVolume.toString());
			//socket.setVolume(avrVolume.toString());
		}


		private function checkVolume():void
		{
			if ((avrVolume < 0))
			{
				avrVolume = 0;
			}
			if ((avrVolume > 82))
			{
				avrVolume = 82;
			}
			volumeTxt.text = "-" + avrVolume.toString() + ".0 dBm";
		}

		// handle settigs input resizing stuff

		private function textHandlerInit():void
		{
			//settingsContent.avrTxt.

			settingsContent.avrNAMETxt.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_ACTIVATE, IMEHandlerActivating );
			settingsContent.avrNAMETxt.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, IMEHandlerDeactivating);

			settingsContent.avrMACTxt.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_ACTIVATE, IMEHandlerActivating );
			settingsContent.avrMACTxt.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, IMEHandlerDeactivating);

			settingsContent.avrIPTxt.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_ACTIVATE, IMEHandlerActivating );
			settingsContent.avrIPTxt.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, IMEHandlerDeactivating);

			settingsContent.avrPORTTxt.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_ACTIVATE, IMEHandlerActivating );
			settingsContent.avrPORTTxt.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, IMEHandlerDeactivating);

		}

		private function IMEHandlerActivating(event:SoftKeyboardEvent):void
		{
			trace( "DISPATCHED: " + event.type + " -- " + event.triggerType + " -- " + event.currentTarget.name );
			var txtField:String = event.currentTarget.name;
			var item = settingsContent.getChildByName(txtField);
			item.border = true;
			item.background = true;
			item.height = 40;
			item.width = stage.stageWidth - 20;
			item.x = 10;
		}

		private function IMEHandlerDeactivating(event:SoftKeyboardEvent):void
		{
			trace( "DISPATCHED: " + event.type + " -- " + event.triggerType + " -- " + event.currentTarget.name );
			var txtField:String = event.currentTarget.name;
			var item = settingsContent.getChildByName(txtField);

			item.border = false;
			item.background = false;

			item.height = 20;
			item.width = 160;
			item.x = 139;
		}


		// STAGEVIEW STUFF for local server

		public function StageWebViewExample(event:MouseEvent=null):void
		{
			settingsContent.closeButt.visible = true;
			webView.stage = this.stage;
			webView.viewPort = new Rectangle(0,0,stage.stageWidth,stage.stageHeight - 45);
			webView.loadURL( "http://"+avrIP );
			settingsContent.closeButt.addEventListener(MouseEvent.CLICK,stageViewCloseHandler);
			TweenLite.to(navpanelButt, .25, {y: (stage.stageHeight+1) });
			TweenLite.to(settingsButt, .25, {y: (stage.stageHeight+1) });
			TweenLite.to(receiverButt, .25, {y: (stage.stageHeight+1) });
			TweenLite.to(settingsButtHigh, .25, {y: (stage.stageHeight+1) });
			TweenLite.to(receiverButtHigh, .25, {y: (stage.stageHeight+1) });
			TweenLite.to(rcvrTxt_mc, .25, {y: (stage.stageHeight+1) });
			TweenLite.to(settingsTxt_mc, .25, {y: (stage.stageHeight+1) });

		}

		private function stageViewCloseHandler(event:MouseEvent):void
		{
			settingsContent.closeButt.removeEventListener(MouseEvent.CLICK,stageViewCloseHandler);
			webView.viewPort = new Rectangle(0,0,0,0);
			TweenLite.to(navpanelButt, .25, {y: (438.15) });
			TweenLite.to(settingsButt, .25, {y: (440.45) });
			TweenLite.to(receiverButt, .25, {y: (442.40) });
			TweenLite.to(settingsButtHigh, .25, {y: (440.45) });
			TweenLite.to(receiverButtHigh, .25, {y: (442.40) });
			TweenLite.to(rcvrTxt_mc, .25, {y: (467) });
			TweenLite.to(settingsTxt_mc, .25, {y: (467) });
			settingsContent.closeButt.visible = false;
		}




		// BEGIN PREFS


		/**
		* Called when the application is rendered. The method points the prefsFile File object 
		* to the "preferences.xml prefsFile in the Apollo application store directory, which is uniquely 
		* defined for the application. It then calls the readXML() method, which reads the XML data.
		*/
		public function appComplete():void
		{
			prefsFile = File.applicationStorageDirectory;
			prefsFile = prefsFile.resolvePath("preferences.xml");
			trace("PREFS LOCATION: "+prefsFile.nativePath, prefsFile.name);

			if (prefsFile.exists)
			{
				trace("PREFS SAVE START");
				// stage.nativeWindow.addEventListener(Event.CLOSING, windowClosingHandler); 
				readXML();
			}
			else
			{
				trace("Unable to find preferences.xml - must be first launch - make new file from template");
				var newPrefs:File = File.applicationDirectory.resolvePath("preferences.xml");
				newPrefs.copyTo(File.applicationStorageDirectory.resolvePath("preferences.xml"));
				readXML();
			}
		}

		/**
		* Called when the application is first rendered, and when the user clicks the Save button.
		* If the preferences file *does* exist (the application has been run previously), the method 
		* sets up a FileStream object and reads the XML data, and once the data is read it is processed. 
		* If the file does not exist, the method calls the saveData() method which creates the file. 
		*/
		private function readXML():void
		{
			stream = new FileStream();

			if (prefsFile.exists)
			{
				stream.open(prefsFile, FileMode.READ);
				processXMLData();
			}
			else
			{
				saveData();
			}
			//stage.nativeWindow.visible = true;
		}

		/**
		* Called after the data from the prefs file has been read. The readUTFBytes() reads
		* the data as UTF-8 text, and the XML() function converts the text to XML. The x, y,
		* width, and height properties of the main window are then updated based on the XML data.
		*/
		private function processXMLData():void
		{
			prefsXML = XML(stream.readUTFBytes(stream.bytesAvailable));
			stream.close();
			trace(prefsXML.saveDate);
			trace(prefsXML.AVR_IP);

			avrAVR = prefsXML.AVR;
			avrName = prefsXML.AVR_NAME;
			avrIP = prefsXML.AVR_IP;
			avrPORT = parseInt(prefsXML.AVR_PORT);
			avrMAC = prefsXML.AVR_MAC;
			avrUPNP = Boolean(prefsXML.AVR_UPNP);

			settingsContent.avrTxt.text = avrAVR;
			settingsContent.avrNAMETxt.text = avrName;
			settingsContent.avrIPTxt.text = avrIP;
			settingsContent.avrPORTTxt.text = avrPORT.toString();
			settingsContent.avrMACTxt.text = avrMAC;
			
			//avrINIT=true;
			//

			/*
			stage.nativeWindow.x = prefsXML.windowState.@x;
			stage.nativeWindow.y = prefsXML.windowState.@y;
			stage.nativeWindow.width = prefsXML.windowState.@width;
			stage.nativeWindow.height = prefsXML.windowState.@height;
			*/
		}

		/**
		* Called when the window is closing (and the closing event is dispatched.
		*/
		private function windowClosingHandler(event:Event):void
		{
			saveData();
		}

		/**
		* Called when the user clicks the Save button or when the window
		* is closing.
		*/
		private function saveData():void
		{
			trace("SAVING DATA");
			createXMLData();
			writeXMLData();
		}

		/**
		* Creates the XML object with data based on the window state 
		* and the current time.
		*/
		private function createXMLData():void
		{
			prefsXML = <preferences/>;
			
			/* */
			prefsXML.saveDate = new Date().toString();
			prefsXML.AVR = avrAVR.toString();
			prefsXML.AVR_NAME = avrName.toString();
			prefsXML.AVR_IP = avrIP.toString();
			prefsXML.AVR_PORT = avrPORT.toString();
			prefsXML.AVR_MAC = avrMAC.toString();
			prefsXML.AVR_UPNP = avrUPNP.toString();
			// stupid workaround for Flash CS 5.5 autoformat bug

		}
		

		/**
		* Called when the NativeWindow closing event is dispatched. The method 
		* converts the XML data to a string, adds the XML declaration to the beginning 
		* of the string, and replaces line ending characters with the platform-
		* specific line ending character. Then sets up and uses the stream object to
		* write the data.
		*/
		private function writeXMLData():void
		{
			var outputString:String = '<?xml version="1.0" encoding="utf-8"?>\n';
			outputString +=  prefsXML.toXMLString();
			outputString = outputString.replace(/\n/g,File.lineEnding);
			stream = new FileStream();
			stream.open(prefsFile, FileMode.WRITE);
			stream.writeUTFBytes(outputString);
			stream.close();

			stream.open(prefsFile, FileMode.READ);
			processXMLData();
		}

		// END PREFS


	}

}
