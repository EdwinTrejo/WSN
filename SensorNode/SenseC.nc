
#include "Timer.h"
#include "printf.h"

module SenseC
{
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;
    interface Read<uint16_t>;
    interface Receive;
    interface AMSend;
    interface PacketField<uint8_t> as PacketRSSI;
  }
}

implementation
{
  // sampling frequency in binary milliseconds
  #define SAMPLING_FREQUENCY 100

  event void Boot.booted() {
    call Timer.startPeriodic(SAMPLING_FREQUENCY);
  }

  event void Timer.fired()
  {
    call Read.read();
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) 
  {
    //
    return bufPtr;
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) 
  {
    //
  }

  event void Read.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS){
      //printf("Message: ");
      //putchar(data);
      //printf("\r\n");
      printf("%u\r\n", data);
      //printfflush();

      if (data & 0x0004)
        call Leds.led2On();
      else
        call Leds.led2Off();
      if (data & 0x0002)
        call Leds.led1On();
      else
        call Leds.led1Off();
      if (data & 0x0001)
        call Leds.led0On();
      else
        call Leds.led0Off();
    }
  }
}