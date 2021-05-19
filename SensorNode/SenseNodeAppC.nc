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
  components Atm128Uart0C as uart;

  SenseNodeC -> RF230ActiveMessageC.PacketRSSI;
  SenseNodeC.Boot -> MainC;
  SenseNodeC.Leds -> LedsC;
  SenseNodeC.Timer -> TimerMilliC;
  SenseNodeC.Read -> Sensor;
  SenseNodeC.RadioControl -> ActiveMessageC;
  SenseNodeC.AMSend -> AMSenderC;
  SenseNodeC.Receive -> AMReceiverC;
  SenseNodeC.Packet -> ActiveMessageC;

  SenseNodeC.UartByte -> uart.UartByte;
  SenseNodeC.UartStream -> uart.UartStream;
}
