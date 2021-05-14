
 #define NEW_PRINTF_SEMANTICS
 #include "printf.h"

configuration SenseAppC
{
}
implementation {

  components SenseC, MainC, LedsC, new TimerMilliC(), new DemoSensorC() as Sensor;
  components PrintfC;
  components SerialStartC;
  components ActiveMessageC;
  components RF230ActiveMessageC;

  SenseC.Boot -> MainC;
  SenseC.Leds -> LedsC;
  SenseC.Timer -> TimerMilliC;
  SenseC.Read -> Sensor;
  SenseC.Receive -> ActiveMessageC.Receive[240];
  SenseC.AMSend -> ActiveMessageC.AMSend[240];
}