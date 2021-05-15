#include "definitions.h"

configuration SenseNodeAppC {
}
implementation {
  components new DemoSensorC() as Sensor;
  components SenseNodeC, MainC;
  components ActiveMessageC;
  components new AMSenderC(AM_DEMO_MESSAGE), new AMReceiverC(AM_DEMO_MESSAGE);
  components LedsC;
  components new TimerMilliC();
  components PrintfC;
  components SerialStartC;
  components RF230ActiveMessageC;

  SenseNodeC -> RF230ActiveMessageC.PacketRSSI;
  SenseNodeC.Boot -> MainC;
  SenseNodeC.Leds -> LedsC;
  SenseNodeC.Timer -> TimerMilliC;

  SenseNodeC.Read -> Sensor;

  SenseNodeC.RadioControl -> ActiveMessageC;
  SenseNodeC.AMSend -> AMSenderC;
  SenseNodeC.Receive -> AMReceiverC;
  SenseNodeC.Packet -> ActiveMessageC;

  //SenseNodeC.AMSend -> ActiveMessageC.AMSend[AM_DEMO_MESSAGE];
  //SenseNodeC.Receive -> ActiveMessageC.Receive[AM_DEMO_MESSAGE];

  //SenceC.Light -> Photo.ExternalPhotoAdc;
}
