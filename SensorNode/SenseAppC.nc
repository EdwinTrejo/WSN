 #include "definitions.h"

configuration SenseAppC {
}
implementation {
  components SenseC, MainC, LedsC, new TimerMilliC();
  components new DemoSensorC() as Sensor;
  components PrintfC;
  components SerialStartC;
  components ActiveMessageC;
  components RF230ActiveMessageC;

  SenseC -> RF230ActiveMessageC.PacketRSSI;
  SenseC.Boot -> MainC;
  SenseC.Leds -> LedsC;
  SenseC.Timer -> TimerMilliC;
  SenseC.Read -> Sensor;
  SenseC.Receive -> ActiveMessageC.Receive[240];
  SenseC.AMSend -> ActiveMessageC.AMSend[240];
}
