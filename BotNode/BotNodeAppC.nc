/*
 * Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
 */
 #include "definitions.h"
configuration BotNodeAppC {
}
implementation {
  components MainC, LedsC, ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;
  components new TimerMilliC() as Timer0;
  components  Atm128Uart0C as uart;
  components new AMSenderC(AM_IROBOT);
  components new AMReceiverC(AM_IROBOT);

  components BotNodeC as App;

  App.Boot -> MainC.Boot;
	App.Leds -> LedsC.Leds;
  App.SerialControl -> Serial;
	App.UartByte -> uart.UartByte;
	App.UartStream -> uart.UartStream;
	App.Timer0 -> Timer0;

	App.Packet->AMSenderC.Packet;
	App.AMPacket->AMSenderC.AMPacket;
	App.RadioControl->Radio.SplitControl;
	App.RadioSend -> AMSenderC.AMSend;
	App.RadioReceive -> AMReceiverC.Receive;
}
