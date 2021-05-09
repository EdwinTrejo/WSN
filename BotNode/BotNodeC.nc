/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.
 * All rights reserved.
 */

#include "AM.h"
#include "Serial.h"
#include "definitions.h"

//RssiDistMsg
module BotNodeC {
  uses {
    interface Boot;
    interface Leds;
    //this is being used like a signal to show that everything is fine
    interface Timer<TMilli> as Timer0;

    //to start and stop serial section of system
    interface SplitControl as SerialControl;
    interface SplitControl as RadioControl;

    //for sending and receiving one byte at a time -- no interrupts here
    interface UartByte;
    //multiple byte send and receive, byte level receive interrupt
    interface UartStream;

    interface Packet;
		interface AMPacket;
		interface AMSend as RadioSend;
		interface Receive as RadioReceive;
  }
}

implementation {
  uint8_t uartQueueBufs[UART_QUEUE_LEN];
  //uint8_t * uartQueue[UART_QUEUE_LEN];
  uint8_t uartIn, uartOut;
  bool uartBusy, uartFull;

  message_t radioQueueBufs[RADIO_QUEUE_LEN];
  message_t * ONE_NOK radioQueue[RADIO_QUEUE_LEN];
  uint8_t radioIn, radioOut;
  bool radioBusy, radioFull;

  //PARAMTERS MADE BY ME
  nx_uint16_t rssi;
  nx_uint16_t light;
  uint8_t selectedMoteTarget = 1;

  message_t pkt;
  bool radioBusy = FALSE;
  bool serialBusy = FALSE;

  //from serial port
  uint8_t receivedByte;
  uint8_t selectedRobot = 1;
  bool robotSelectMode = FALSE;

  //I assume 0 as gateway  --default destination
  uint8_t destinationAddress = 0;

  //function definitions
  void Fail(uint8_t code);
  void Pass();
  task void SendToSerial();
  task void SendToRadio();
  void SendByteToSerial(U8T new_command[], U16T len);
  U8T GetHighByte(S16T num);
  U8T GetLowByte(S16T num);

  void MoveForward(S16T dist, S16T velocity);
  void MoveBackwards(S16T dist, S16T velocity);

  void TurnRight();
  void TurnLeft();

  /************ Boot ************/
  event void Boot.booted() {
    //boot need not be atomic

    //setting up UART queue. this will be filled by
    //packets received via radio and will be accessed by UART
    uint8_t i;
    uartIn = uartOut = 0;
		uartBusy = FALSE;
		uartFull = TRUE;

    //Radio queue, filled by UART and consumed by Radio
		for(i = 0; i < RADIO_QUEUE_LEN; i++) {
			radioQueue[i] = &radioQueueBufs[i];
    }
		radioIn = radioOut = 0;
		radioBusy = FALSE;
		radioFull = TRUE;

/*
    //mote needs to identify which mote targetted it
    if(TOS_NODE_ID == 0)
    {
      destinationAddress = selectedRobot;
    }
*/
    call RadioControl.start();
  }

  //radio
  event void RadioControl.startDone(error_t error) {
		if(error == SUCCESS) {
			radioFull = FALSE;
			call SerialControl.start();
		}
		else {
			Fail(1);
			call RadioControl.start();//try again
		}
	}

  event void RadioSend.sendDone(message_t * msg, error_t error) {
    if(error != SUCCESS)
      Fail(2);
    else
      atomic if(msg == radioQueue[radioOut])
      //I think I can remove this since I only have one place to send to radio and this always will be from same source.
    {
      if(++radioOut >= RADIO_QUEUE_LEN)
        radioOut = 0;
      if(radioFull)
        radioFull = FALSE;
    }

    post SendToRadio();

  }

  event void RadioControl.stopDone(error_t error) {
    //mote received the message succesfully
	}

  event void SerialControl.startDone(error_t error) {
    //write to the irobot
		if(error == SUCCESS) {
			uartFull = FALSE;
			if(call UartStream.enableReceiveInterrupt() != SUCCESS) {
				Fail(1);
			}
			else {
				call Timer0.startPeriodic(TIMER_INTERVAL);
			}

		}
		else {
			Fail(1);
			call SerialControl.start(); //try again
		}
	}

  event void Timer0.fired() {
    Pass();
  }

  event void SerialControl.stopDone(error_t error) {
    //serial connection send was complete
	}

  async event void UartStream.receivedByte(uint8_t byte) {
    //can receive a stream from the irobot
    //more like a single byte
		atomic if( ! radioFull) {
      RssiDistMsg * btrpkt = (RssiDistMsg * )(call Packet
					.getPayload(radioQueue[radioIn], sizeof(RssiDistMsg)));

			btrpkt->nodeid = TOS_NODE_ID;
			btrpkt->rssi = byte;

			if(++radioIn >= RADIO_QUEUE_LEN) {
				    radioIn = 0;
        }
			if(radioIn == radioOut) {
				radioFull = TRUE;
      }

			if( ! radioBusy) {
				post SendToRadio();
				radioBusy = TRUE;
			}
		}
		else {
			   Fail(2);
      }
	}

  event message_t * RadioReceive.receive(message_t * msg, void * payload, uint8_t len) {
		atomic {
			if( ! uartFull) {
				if(len == sizeof(RssiDistMsg)) {
          //this will be correct always since we only have one kind of packets so far
					RssiDistMsg * btrpkt = (RssiDistMsg * ) payload;
					uartQueueBufs[uartIn] = btrpkt->rssi;
					uartIn = (uartIn + 1) % UART_QUEUE_LEN;

					if(uartIn == uartOut)
						uartFull = TRUE;

					if( ! uartBusy) {
						post SendToSerial();
						uartBusy = TRUE;
					}

				}
			}
			else {
				Fail(3);
			}
		}
		return msg;
	}

  void task SendToRadio() {

    atomic if(radioIn == radioOut && ! radioFull) {
      radioBusy = FALSE;
      return;
    }

    if(call RadioSend.send(destinationAddress, radioQueue[radioOut],
        sizeof(RssiDistMsg)) == SUCCESS)
      Pass();
    else {
      Fail(2);
      post SendToRadio();
    }
  }

  task void SendToSerial() {

    atomic if(uartIn == uartOut && ! uartFull) {
      uartBusy = FALSE;
      return;
    }

    atomic {
      MoveForward(200, 50);
      TurnRight();
      MoveBackwards(200, -50);
      TurnLeft();
    }

    post SendToSerial();
  }

  async event void UartStream.sendDone(uint8_t * buf, uint16_t len, error_t error) {
		if(error == FAIL) {
			Fail(3);
		}
		else {
			atomic {
        //this must be always true in my case sine we only have one user of the queue
				if(buf == &uartQueueBufs[uartOut]){
					if(++uartOut >= UART_QUEUE_LEN)
						uartOut = 0;
					if(uartFull)
						uartFull = FALSE;
				}
			}
		}
		post SendToSerial();
	}

  async event void UartStream.receiveDone(uint8_t * buf, uint16_t len, error_t error) {
	}

  void TurnRight() {
    //turn right
    //drive CmdDrive, F, F, F, F
    S16T angle = (32767/2); //up to 32767
    U8T new_msg[] = {CmdStart, CmdSafe, CmdDrive, 255, 255, 255, 255};
    U8T new_msg_dist[] = {CmdWaitAngle, 0, 0};
    new_msg_dist[1] = GetHighByte(angle);
    new_msg_dist[2] = GetLowByte(angle);
    SendByteToSerial(new_msg, 7);
    SendByteToSerial(new_msg_dist, 3);
  }

  void TurnLeft() {
    //turn left
    //drive CmdDrive, 0, 0, 0, 1
    S16T angle = -(32767/2); //up to 32767
    U8T new_msg[] = {CmdStart, CmdSafe, CmdDrive, 0, 0, 0, 1};
    U8T new_msg_dist[] = {CmdWaitAngle, 0, 0};
    new_msg_dist[1] = GetHighByte(angle);
    new_msg_dist[2] = GetLowByte(angle);
    SendByteToSerial(new_msg, 7);
    SendByteToSerial(new_msg_dist, 3);
  }

  void MoveForward(S16T dist, S16T velocity) {
    U8T new_msg[] = {CmdStart, CmdSafe, CmdDrive, 0, 0, RADIUS_HIGH, RADIUS_LOW};
    U8T dist_msg[] = {CmdWaitDistance, 0, 0};
    //drive
    new_msg[3] = GetHighByte(velocity);
    new_msg[4] = GetLowByte(velocity);
    //wait until distance
    dist_msg[1] = GetHighByte(dist);
    dist_msg[2] = GetLowByte(dist);
    SendByteToSerial(new_msg, 7);
    SendByteToSerial(dist_msg, 3);
  }

  void MoveBackwards(S16T dist, S16T velocity) {
    U8T new_msg[] = {CmdStart, CmdSafe, CmdDrive, 0, 0, RADIUS_HIGH, RADIUS_LOW};
    U8T new_msg_dist[] = {CmdWaitDistance, 0, 0};
    S16T dist_neg = -1 * dist;
    //drive
    new_msg[3] = GetHighByte(velocity);
    new_msg[4] = GetLowByte(velocity);
    //wait until distance
    new_msg_dist[1] = GetHighByte(dist_neg);
    new_msg_dist[2] = GetLowByte(dist_neg);
    SendByteToSerial(new_msg, 7);
    SendByteToSerial(new_msg_dist, 3);
  }

  U8T GetHighByte(S16T num) {
    //mult is multiplier constant
    return (num >> 8);
  }

  U8T GetLowByte(S16T num) {
    //mult is multiplier constant
    return ((num << 8) >> 8);
  }

  void SendByteToSerial(U8T new_command[], U16T len) {
    atomic if(uartIn == uartOut && ! uartFull) {
      uartBusy = FALSE;
      return;
    }

    if(call UartStream.send(new_command, len) == SUCCESS) {
      Pass();
    }
    else {
      Fail(3);
    }
  }

  void Fail(uint8_t code) {
    //you have failed B
    /*
      uint8_t Leds = call Leds.get();
      call Leds.set(Leds & 4); //turn off Leds 0 and 1 (Red and Green Leds), don't change led 2
      Leds = call Leds.get();
      call Leds.set(code | Leds);
    */
  }

  void Pass() {
    call Leds.led2Toggle();	// blink led2 (Yellow LED), used as a heartbeat
  }

}
