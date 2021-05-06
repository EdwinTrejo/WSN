/*
 * Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
 */
 #include "definitions.h"
configuration BotNodeAppC {
  provides interface Intercept as RadioIntercept[am_id_t amid];
  provides interface Intercept as SerialIntercept[am_id_t amid];
}
implementation {
  components MainC, BotNodeC, LedsC;
  components ActiveMessageC as Radio, SerialActiveMessageC as Serial;

  RadioIntercept = BotNodeC.RadioIntercept;
  SerialIntercept = BotNodeC.SerialIntercept;

  MainC.Boot <- BotNodeC;

  BotNodeC.RadioControl -> Radio;
  BotNodeC.SerialControl -> Serial;

  BotNodeC.UartSend -> Serial;
  BotNodeC.UartReceive -> Serial;
  BotNodeC.UartPacket -> Serial;
  BotNodeC.UartAMPacket -> Serial;

  BotNodeC.RadioSend -> Radio;
  BotNodeC.RadioReceive -> Radio.Receive;
  BotNodeC.RadioSnoop -> Radio.Snoop;
  BotNodeC.RadioPacket -> Radio;
  BotNodeC.RadioAMPacket -> Radio;

  BotNodeC.Leds -> LedsC;
}
