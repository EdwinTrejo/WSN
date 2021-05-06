#define NEW_PRINTF_SEMANTICS
#include "printf.h"
configuration LEDTestAppC
{
}
implementation
{
  components MainC, LEDTestC as App, LedsC;
  components new TimerMilliC() as Timer;
  components PrintfC;
  components SerialStartC;
  components ActiveMessageC;
  components RF230ActiveMessageC;

  App -> RF230ActiveMessageC.PacketRSSI;

  App.Boot -> MainC.Boot;

  App.Receive -> ActiveMessageC.Receive[240];
  App.AMSend -> ActiveMessageC.AMSend[240];
  App.SplitControl -> ActiveMessageC;
  App.Timer -> Timer;
  App.Leds -> LedsC;
}
