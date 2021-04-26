#include "Timer.h"
#include "printf.h"
module LEDTestC @safe()
{
  uses interface Timer<TMilli> as Timer;
  uses interface Boot;
  uses interface Receive;
  uses interface AMSend;
  uses interface Leds;
  uses interface SplitControl;
}
implementation
{
  message_t packet;

  bool locked;
  uint8_t counter = 0;

  event void Boot.booted()
  {
    call SplitControl.start();
    //call Timer.startPeriodic( 250 );
  }

  void DBGM(const char* message)
  {
    printf(message);
    printfflush();
  }

  event void Timer.fired()
  {
    counter++;
    if (locked) {
      return;
    }
    else if (call AMSend.send(AM_BROADCAST_ADDR, &packet, 0) == SUCCESS) {
      call Leds.led0On();
      locked = TRUE;
      DBGM("Message Sent\r\n");
    }
    /*if (TOS_NODE_ID == 0) {
      call Leds.led0Toggle();
      printf("Print for Base Station\r\n");
    	printfflush();
    } else if (TOS_NODE_ID == 1) {
      call Leds.led1Toggle();
      printf("Print for Node 1\r\n");
    	printfflush();
    } else if (TOS_NODE_ID == 2) {
      call Leds.led2Toggle();
      printf("Print for Node 2\r\n");
    	printfflush();
    }*/
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    call Leds.led1Toggle();
    DBGM("Message Received\r\n");
    return bufPtr;
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
      call Leds.led0Off();
    }
  }

  event void SplitControl.startDone(error_t err) {
    call Timer.startPeriodic(1000);
  }

  event void SplitControl.stopDone(error_t err) {
  }
}
