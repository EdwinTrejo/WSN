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
    interface PacketField<uint8_t> as PacketRSSI;
    interface Leds;
  }
}

implementation {
  message_t packet; //buf
  message_t * rcv_packet; //receivedBuf

  task void readSensor();
  task void sendPacket();
  task void receiveRobotInstruction();
  uint16_t getRssi(message_t *message);

  event void Boot.booted() {
    call RadioControl.start();
  }

  event void Timer.fired() {
    if (TOS_NODE_ID != ROBOT_MOTE)
      post readSensor();
    else
      // something else , I think its check the
      // message buffer and writo to serial
      post receiveRobotInstruction();
  }

  event void RadioControl.startDone(error_t err) {
    if (TOS_NODE_ID != ROBOT_MOTE)
      call Timer.startPeriodic(SAMPLING_FREQUENCY);
    else
      call Timer.startPeriodic(ROBOT_LISTEN_FREQUENCY);
  }

  event void RadioControl.stopDone(error_t err) {}

  task void readSensor() {
    if (call Read.read() != SUCCESS)
      post readSensor();
  }

  task void receiveRobotInstruction() {
    RobotMsg * payload = (RobotMsg *)call Packet.getPayload(&packet, sizeof(RobotMsg));
    uint8_t new_ins = getchar();
    payload->nodeid = TOS_NODE_ID;
    payload->instruction = new_ins;
    post sendPacket();
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    //message was received
    if (TOS_NODE_ID == GATEWAY_MOTE) {
      LightMsg * _msg = (LightMsg *)payload;
      uint8_t rssi = getRssi(bufPtr);
      //LightMsg * _msg = (LightMsg *)bufPtr;
      printf("RSSI:%u\r\n", rssi);
      printf("ID:%u\r\n", _msg->nodeid);
      printf("LIGHT:%u\r\n", _msg->light);
      call Leds.led2Toggle();
    }
    else if (TOS_NODE_ID == ROBOT_MOTE) {
      //message type will include a byte to run the code
      RobotMsg * _msg = (RobotMsg *)payload;
      if (_msg->nodeid == GATEWAY_MOTE) {
        uint8_t serial_instruction = _msg->instruction;
        putchar(serial_instruction);
        call Leds.led1Toggle();
      }
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

    if (TOS_NODE_ID == GATEWAY_MOTE && TOS_NODE_ID != ROBOT_MOTE) {
      //still have to send the data
      printf("ID:%u\r\n", TOS_NODE_ID);
      printf("LIGHT:%u\r\n", data);
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

  uint16_t getRssi(message_t *message)
  {
    if(call PacketRSSI.isSet(message))
      return (uint16_t) call PacketRSSI.get(message);
    else
      return 0xFFFE;
  }

  task void sendPacket() {
    //sender
    if (TOS_NODE_ID != GATEWAY_MOTE && TOS_NODE_ID != ROBOT_MOTE) {
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(LightMsg)) != SUCCESS) {
        post sendPacket();
      }
    }
    else if (TOS_NODE_ID == GATEWAY_MOTE) {
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(RobotMsg)) != SUCCESS) {
        post sendPacket();
      }
    }
  }

}
