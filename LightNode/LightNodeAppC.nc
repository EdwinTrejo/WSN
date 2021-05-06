#include "definitions.h"
configuration LightNodeAppC
{
}
implementation {
  components ActiveMessageC, LedsC, PrintfC, SerialStartC, MainC;
  components new TimerMilliC() as Timer;
  components new DemoSensorC() as Sensor;
  components new AMSenderC(AM_RSSIMSG) as RssiMsgSender;
  components  RF230ActiveMessageC;

  components LightNodeC as App;

  App -> RF230ActiveMessageC.PacketRSSI;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer -> Timer;
  App.Read -> Sensor;

  App.RssiMsgSend -> RssiMsgSender;
  App.RadioControl -> ActiveMessageC;
}

/*
 * Copyright (c) 2006, Technische Universitaet Berlin
 * All rights reserved.
 */

/**
 *
 * Sensing demo application. See README.txt file in this directory for usage
 * instructions and have a look at tinyos-2.x/doc/html/tutorial/lesson5.html
 * for a general tutorial on sensing in TinyOS.
 *
 * @author Jan Hauer
 */
