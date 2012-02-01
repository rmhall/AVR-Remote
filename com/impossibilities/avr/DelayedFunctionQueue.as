package com.impossibilities.avr 
{
	import flash.events.Event;
	import flash.display.Sprite;

	public class DelayedFunctionQueue
	{
		protected var queue:Array;
		protected var dispatcher:Sprite;
		protected var frameCnt:Number = 0;

		public function DelayedFunctionQueue()
		{
			queue = new Array();
			dispatcher = new Sprite();
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
				dispatcher.addEventListener( Event.ENTER_FRAME, count, false, 0, true );
			}
		}

		protected function count(event:Event):void
		{
			frameCnt++;
			if (frameCnt>=4)
			{
				frameCnt = 0;
				onEF(null);
			}
		}

		protected function onEF( event:Event ):void
		{
			var delegateFn:Function = queue.shift(); //queue.pop();
			//trace("Executing Command Queue: ");
			delegateFn();
			if (queue.length <= 0)
			{
				dispatcher.removeEventListener( Event.ENTER_FRAME, count, false );
			}
		}
	}
}