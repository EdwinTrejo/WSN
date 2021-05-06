#ifndef I_ROBOT_H
#define I_ROBOT_H

enum {
	AM_IROBOT = 44,
	TIMER_INTERVAL = 250,
	RobotSelectCommand = 255,
	//I am using this to select a robot. so If gateway sees this in its serial port,
	//will assume next byte for selecting a robot. after that all bytes
	//will be assumed as regular commands until again it sees 255
	UART_QUEUE_LEN = 20,
	RADIO_QUEUE_LEN = 20,
};

typedef nx_struct iRobotMsg {
	nx_uint16_t nodeid;
	nx_uint8_t cmd;

} iRobotMsg;

#endif /* I_ROBOT_H */
