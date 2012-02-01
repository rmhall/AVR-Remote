package com.impossibilities.avr 
{
	//import flash.events.Event;
	//import flash.display.Sprite;
	import flash.utils.setInterval;
	import flash.utils.clearInterval;

	public class CommandQueue
	{
		protected var queue:Array;
		//protected var dispatcher:Sprite;
		protected var queueRef:Number;

		public function CommandQueue()
		{
			queue = new Array();
			//dispatcher = new Sprite();
		}

		public function add( func:Function, ... args ):void
		{
			var delegateFn:Function = function():void
			        {
			            func.apply( null, args );
			        };
			queue.push( delegateFn );
			if (queue.length == 1)
			{
				queueRef = setInterval(onEF, 100)
			}
		}

		protected function onEF():void
		{
			var delegateFn:Function = queue.shift(); //queue.pop();
			//trace("Executing Command Queue: ");
			delegateFn();
			if (queue.length <= 0)
			{
				clearInterval(queueRef);
			}
		}
	}
}