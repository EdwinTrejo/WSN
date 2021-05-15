#include "definitions.h"

module SenseNodeC {
  uses {
    interface Boot;
    interface Read<uint16_t>;
    interface SplitControl as RadioControl;
    interface AMSend;
    interface Receive;
    interface Packet;

    interface Timer<TMilli>;
    //interface ADC as Light;
    //interface WriteData;
    //interface ReadData;
    //interface PacketField<uint8_t> as PacketRSSI;
    interface Leds;
  }
}

implementation {
  message_t packet; //buf
  message_t * rcv_packet; //receivedBuf

  task void readSensor();
  task void sendPacket();

  event void Boot.booted() {
    call RadioControl.start();
  }

  event void Timer.fired() {
    post readSensor();
    //call Read.read();
  }

  event void RadioControl.startDone(error_t err) {
    if (TOS_NODE_ID != ROBOT_MOTE)
      call Timer.startPeriodic(SAMPLING_FREQUENCY);
  }

  event void RadioControl.stopDone(error_t err) {}

  task void readSensor() {
    if (call Read.read() != SUCCESS)
      post readSensor();
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    //message was received
    if (TOS_NODE_ID == GATEWAY_MOTE) {
      LightMsg * _msg = (LightMsg *)payload;
      //LightMsg * _msg = (LightMsg *)bufPtr;
      printf("%u\r\n", _msg->nodeid);
      printf("%u\r\n", _msg->light);
      call Leds.led2Toggle();
    }
    rcv_packet = bufPtr;
    return bufPtr;
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    //sender
    if (error != SUCCESS)
      post sendPacket();
  }

  event void Read.readDone(error_t result, uint16_t data)
  {
    //sender
    if (result != SUCCESS)
      post readSensor();
    else {
      LightMsg * payload = (LightMsg *)call Packet.getPayload(&packet, sizeof(LightMsg));
      payload->nodeid = TOS_NODE_ID;
      payload->light = data;
      post sendPacket();
    }

    if (TOS_NODE_ID == GATEWAY_MOTE) {
      //still have to send the data
      printf("%u\r\n", TOS_NODE_ID);
      printf("%u\r\n", data);
    }
    /*
    if (result == SUCCESS) {
      call Leds.led1On();
      if (TOS_NODE_ID != GATEWAY_MOTE) {
        // MOTE #1 is the gateway mote
        LightMsg _msg;
        _msg.nodeid = TOS_NODE_ID;
        _msg.light = data;
        //memcpy target, source, size
        memcpy(&packet, &_msg, sizeof(LightMsg));
        call AMSend.send(GATEWAY_MOTE, &packet, sizeof(LightMsg));
      }
      else {
        // if its already the gateway mote
        printf("%u\r\n", TOS_NODE_ID);
        printf("%u\r\n", data);
      }
    }
    else {
      call Leds.led1Off();
    }
    */
  }

  task void sendPacket() {
    //sender
    if (TOS_NODE_ID != GATEWAY_MOTE) {
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(LightMsg)) != SUCCESS) {
        post sendPacket();
      }
    }
  }

}
