#include "AM.h"
#include "Serial.h"
#include "oi.h"
#include "IRobot.h"

module SerialC {
	uses {
		interface Boot;
		interface Leds;
		interface Timer<TMilli> as Timer0; //this is being used like a signal to show that everything is fine
		interface SplitControl as RadioControl;
		interface SplitControl as SerialControl; //to start and stop serial section of system
		interface UartByte; //for sending and receiving one byte at a time -- no interrupts here
		interface UartStream; //multiple byte send and receive, byte level receive interrupt

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

	uint8_t cmd;
	message_t pkt;
	bool radioBusy = FALSE;
	bool serialBusy = FALSE;
	uint8_t receivedByte; //from serial port
	uint8_t selectedRobot = 1;
	bool robotSelectMode = FALSE;
	uint8_t destinationAddress = 0; //I assume 0 as gateway  --default destination

	task void SendToSerial();
	task void SendToRadio();
	void Fail(uint8_t code);
	void OK();

	event void Boot.booted() {
		uint8_t i;
		//setting up UART queue. this will be filled by packets received via radio and will be accessed by UART
		//for(i = 0; i < UART_QUEUE_LEN; i++)
		//	uartQueue[i] = &uartQueueBufs[i];
		uartIn = uartOut = 0;
		uartBusy = FALSE;
		uartFull = TRUE;

		//Radio queue, filled by UART and consumed by Radio
		for(i = 0; i < RADIO_QUEUE_LEN; i++)
			radioQueue[i] = &radioQueueBufs[i];
		radioIn = radioOut = 0;
		radioBusy = FALSE;
		radioFull = TRUE;

		// TOS_NODE_ID value can be set when installing the code
		// on the IRIS mote, where 0 is Gateway and other nodes
		// are any value > 0. E.g:
		// make iris install,0 mib520....etc => (Gateway)
		// make iris install,1 mib520....etc => (Node 1)

		// If this node is the gateway
		if(TOS_NODE_ID == 0)
			destinationAddress = selectedRobot;

		call RadioControl.start();
	}

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

	event void RadioControl.stopDone(error_t error) {
	}

	event void SerialControl.startDone(error_t error) {
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
	event void SerialControl.stopDone(error_t error) {
	}

	////////*************************************************************************uart to radio section

	async event void UartStream.receivedByte(uint8_t byte) {

		atomic if( ! radioFull) {
			iRobotMsg * btrpkt = (iRobotMsg * )(call Packet
					.getPayload(radioQueue[radioIn], sizeof(iRobotMsg)));

			btrpkt->nodeid = TOS_NODE_ID;
			btrpkt->cmd = byte;

			if(++radioIn >= RADIO_QUEUE_LEN)
				radioIn = 0;
			if(radioIn == radioOut)
				radioFull = TRUE;

			if( ! radioBusy) {
				post SendToRadio();
				radioBusy = TRUE;
			}
		}
		else
			Fail(2);
	}

	void task SendToRadio() {

		atomic if(radioIn == radioOut && ! radioFull) {
			radioBusy = FALSE;
			return;
		}

		if(call RadioSend.send(destinationAddress, radioQueue[radioOut],
				sizeof(iRobotMsg)) == SUCCESS)
			OK();
		else {
			Fail(2);
			post SendToRadio();
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

	///***************************************************************end of radio to uart section

	//*******************************************************Radio to Uart Section

	//this will be triggered only and only if the address of the packet is my address or it is broadcast.
	//if we need to handle other packets, we should use snoop receive
	event message_t * RadioReceive.receive(message_t * msg, void * payload,
			uint8_t len) {
		atomic {
			if( ! uartFull) {
				if(len == sizeof(iRobotMsg)){//this will be correct always since we only have one kind of packets so far
					iRobotMsg * btrpkt = (iRobotMsg * ) payload;

					uartQueueBufs[uartIn] = btrpkt->cmd;

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

	task void SendToSerial() {
		atomic if(uartIn == uartOut && ! uartFull) {
			uartBusy = FALSE;
			return;
		}

		if(call UartStream.send(&uartQueueBufs[uartOut], 1) == SUCCESS)
			OK();
		else {
			Fail(3);
			post SendToSerial();
		}
	}

	async event void UartStream.sendDone(uint8_t * buf, uint16_t len,
			error_t error) {
		if(error == FAIL) {
			Fail(3);
		}
		else {
			atomic {
				if(buf == &uartQueueBufs[uartOut]){ //this must be always true in my case sine we only have one user of the queue
					if(++uartOut >= UART_QUEUE_LEN)
						uartOut = 0;
					if(uartFull)
						uartFull = FALSE;
				}
			}
		}
		post SendToSerial();
	}

	//*************************************************************end of Radio to UART section

	void Rest() {
		if(++uartOut >= UART_QUEUE_LEN)
			uartOut = 0;

		if(uartFull)
			uartFull = FALSE;
		post SendToRadio();
	}

	void RealRadioSend() {
		iRobotMsg * btrpkt = (iRobotMsg * )(call Packet.getPayload(&pkt,
				sizeof(iRobotMsg)));

		btrpkt->nodeid = TOS_NODE_ID;
		btrpkt->cmd = uartQueueBufs[uartOut];

		if(TOS_NODE_ID == 0){ //this is the gateway which is connected to the PC
			if(call RadioSend.send(selectedRobot, &pkt, sizeof(iRobotMsg)) == SUCCESS) {
				OK();
			}
			else {
				Fail(0);
				post SendToRadio();
			}

		}
		else { //this is robot side mote
			if(call RadioSend.send(TOS_NODE_ID, &pkt, sizeof(iRobotMsg)) == SUCCESS) {
				OK();
			}
			else {
				Fail(0);
				post SendToRadio();
			}
		}
	}

	async event void UartStream.receiveDone(uint8_t * buf, uint16_t len,
			error_t error) {
	}

	event void Timer0.fired() {
		OK();
	}

	void Fail(uint8_t code) {
		uint8_t leds = call Leds.get();
		call Leds.set(leds & 4); //turn off leds 0 and 1 (Red and Green LEDs), don't change led 2
		leds = call Leds.get();
		call Leds.set(code | leds);
	}

	void OK() {
		call Leds.led2Toggle();	// blink led2 (Yellow LED), used as a heartbeat
	}

}
