
#include "definitions.h"

module SenseC {
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

implementation {
  // sampling frequency in binary milliseconds
  #define SAMPLING_FREQUENCY 100
  message_t packet;

  event void Boot.booted() {
    call Timer.startPeriodic(SAMPLING_FREQUENCY);
  }

  event void Timer.fired() {
    call Read.read();
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    //message was received
    return bufPtr;
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (error == SUCCESS) {
      //message send was success
      if (TOS_NODE_ID != GATEWAY_MOTE) {
        LightMsg * _msg = (LightMsg *)bufPtr;
        printf("%u", LightMsg->nodeid);
        printf("%u", LightMsg->light);
      }
    }
  }

  event void Read.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS) {
      if (TOS_NODE_ID != GATEWAY_MOTE) {
        // MOTE #1 is the gateway mote
        LightMsg _msg;
        _msg.nodeid = TOS_NODE_ID;
        _msg.light = data;
        memcpy(packet, LightMsg, sizeof(LightMsg));
        call AMSend.send(GATEWAY_MOTE, &packet, 0);
      }
      else {
        // if its already the gateway mote
        printf("%u", TOS_NODE_ID);
        printf("%u", data);
      }
    }
  }
}