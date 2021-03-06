#include "definitions.h"

module SenseNodeC {
  uses {
    interface Boot;
    interface Read<uint16_t>;
    interface SplitControl as RadioControl;
    interface UartByte;
    interface UartStream;
    interface AMSend;
    interface Receive;
    interface Packet;
    interface Timer<TMilli>;
    interface PacketField<uint8_t> as PacketRSSI;
    interface Leds;
  }
}

implementation {
  message_t packet_light; //buf
  message_t * rcv_packet_light; //receivedBuf

  message_t packet_robot; //buf
  message_t * rcv_packet_robot; //receivedBuf

  message_t packet_rssi; //buf
  message_t * rcv_packet_rssi; //receivedBuf

  bool gateway_send_robot_message = FALSE;
  bool robot_rx_light = FALSE;

  task void readSensor();
  task void sendPacket();
  task void writeToSerial();
  //task void receiveRobotInstruction();
  uint16_t getRssi(message_t *message);

  event void Boot.booted() {
    call RadioControl.start();
  }

  async event void UartStream.receivedByte(uint8_t byte) {
    atomic {
      RobotMsg * payload = (RobotMsg *)call Packet.getPayload(&packet_robot, sizeof(RobotMsg));
      payload->nodeid = TOS_NODE_ID;
      payload->instruction = byte;
      gateway_send_robot_message = TRUE;
      call Leds.led2Toggle();
      post sendPacket();
    }
  }

  async event void UartStream.receiveDone(uint8_t * buf, uint16_t len,
			error_t error) {
	}

  async event void UartStream.sendDone(uint8_t * buf, uint16_t len,
			error_t error) {
    }

  event void Timer.fired() {
    if (TOS_NODE_ID != ROBOT_MOTE) {
        post readSensor();
    }
    /*
      else if (TOS_NODE_ID == GATEWAY_MOTE) {
        // something else , I think its check the
        // message buffer and writo to serial
        post readSensor();
        //post receiveRobotInstruction();
      }
    */
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

  task void writeToSerial(){
    if (TOS_NODE_ID == ROBOT_MOTE) {
      RobotMsg * payload = (RobotMsg *)call Packet.getPayload(&packet_robot, sizeof(RobotMsg));
      call Leds.led0Toggle();
      putchar(payload->instruction);
    }
  }

  /*
    task void receiveRobotInstruction() {
      //this one is tricky because only the robot will have to listen for two packets at once
      RobotMsg * payload = (RobotMsg *)call Packet.getPayload(&packet_robot, sizeof(RobotMsg));
      uint8_t new_ins = 0;
      atomic {
        new_ins = getchar();
      }
      payload->nodeid = TOS_NODE_ID;
      payload->instruction = new_ins;
      atomic {
        gateway_send_robot_message = TRUE;
      }
      call Leds.led2Toggle();
      post sendPacket();
    }
  */

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    //message was received
    if (TOS_NODE_ID == GATEWAY_MOTE) {
      if(len == sizeof(RssiMsg)) {
        RssiMsg * _msg = (RssiMsg *)payload;
        printf("%u,%u,%u\r\n", _msg->nodeid, _msg->light, _msg->rssi);
        rcv_packet_rssi = bufPtr;
      }
    }
    else if (TOS_NODE_ID == ROBOT_MOTE)
    {
      if(len == sizeof(RobotMsg))
      {
        //RobotMsg * _msg = (RobotMsg *)payload;
        //printf("%c", (char)_msg->instruction);
        rcv_packet_robot = bufPtr;
        robot_rx_light = FALSE;
        post writeToSerial();
      }
      else if (len == sizeof(LightMsg))
      {
        LightMsg * _msg = (LightMsg *)payload;
        RssiMsg * payload_rssi = (RssiMsg *)call Packet.getPayload(&packet_rssi, sizeof(RssiMsg));
        uint8_t rssi = getRssi(bufPtr);
        payload_rssi->nodeid = _msg->nodeid;
        payload_rssi->light = _msg->light;
        payload_rssi->rssi = rssi;
        rcv_packet_light = bufPtr;
        robot_rx_light = TRUE;
        call Leds.led1Toggle();
        post sendPacket();
      }
    }
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
    //read sensor is complete
    if (result != SUCCESS)
      post readSensor();
    else {
      LightMsg * payload = (LightMsg *)call Packet.getPayload(&packet_light, sizeof(LightMsg));
      payload->nodeid = TOS_NODE_ID;
      payload->light = data;

      atomic if (TOS_NODE_ID == GATEWAY_MOTE) {
        gateway_send_robot_message = FALSE;
      }

      post sendPacket();
    }
  }

  uint16_t getRssi(message_t *message)
  {
    if(call PacketRSSI.isSet(message))
      return (uint16_t) call PacketRSSI.get(message);
    else
      return 0xFFFE;
  }

  task void sendPacket() {
    //send a Light reading message relative to the irobot node
    atomic {
      if (TOS_NODE_ID != ROBOT_MOTE && TOS_NODE_ID != GATEWAY_MOTE) {
        if (call AMSend.send(AM_BROADCAST_ADDR, &packet_light, sizeof(LightMsg)) != SUCCESS) {
          post sendPacket();
        }
      }
      else if (TOS_NODE_ID == ROBOT_MOTE) {
        if (call AMSend.send(AM_BROADCAST_ADDR, &packet_rssi, sizeof(RssiMsg)) != SUCCESS) {
          post sendPacket();
        }
      }
      else if (TOS_NODE_ID == GATEWAY_MOTE){
        if (gateway_send_robot_message == TRUE){
          if (call AMSend.send(AM_BROADCAST_ADDR, &packet_robot, sizeof(RobotMsg)) != SUCCESS) {
            post sendPacket();
          }
        }
        else{
          if (call AMSend.send(AM_BROADCAST_ADDR, &packet_light, sizeof(LightMsg)) != SUCCESS) {
            post sendPacket();
          }
        }
      }
     }
  }

}
