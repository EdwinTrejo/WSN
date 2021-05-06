#include "definitions.h"
module LightNodeC
{
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as Timer;
    interface Read<uint16_t>;

    interface AMSend as RssiMsgSend;
    interface SplitControl as RadioControl;
    interface PacketField<uint8_t> as PacketRSSI;
  }
}
implementation
{
  message_t msg;

  event void Boot.booted(){
    call RadioControl.start();
  }

  //event void Boot.booted() {
  //  call Timer.startPeriodic(SAMPLING_FREQUENCY);
  //}

  //event void Timer.fired()
  //{
  //  call Read.read();
  //}

  event void RadioControl.startDone(error_t result){
    call Timer.startPeriodic(TIME_INTERVAL);
  }

  event void RadioControl.stopDone(error_t result){}

  event void Timer.fired()
  {
    call Read.read();
    call RssiMsgSend.send(AM_BROADCAST_ADDR, &msg, sizeof(RssiMsg));
  }

  uint16_t getRssi(message_t *message)
  {
    if(call PacketRSSI.isSet(message))
      return (uint16_t) call PacketRSSI.get(message);
    else
      return 0xFFFE;
  }

  event void RssiMsgSend.sendDone(message_t *m, error_t error)
  {
    //RSSI MESSAGE SEND
    //atomic
    //{
      printf("\r\nRSSI: %u\r\n", getRssi(m));
    //}
  }

  event void Read.readDone(error_t result, uint16_t data)
  {
    //READ FROM SENSOR COMPLETE
    if (result == SUCCESS){
      //atomic
      //{
        printf("DATA: %u\r\n", data);
      //}
      atomic
      {
        printfflush();
      }

      /*
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
      */
    }
  }
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
