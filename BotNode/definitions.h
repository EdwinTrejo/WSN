#ifndef DEFINITIONS_H__
#define DEFINITIONS_H__

#include "oi.h"

#define NEW_PRINTF_SEMANTICS

#define U16T uint16_t
#define U8T uint8_t

#define S16T int16_t
#define S8T int8_t

#define RADIUS_HIGH 128
#define RADIUS_LOW 0

#include "Timer.h"
#include "printf.h"

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

typedef nx_struct RssiDistMsg {
	nx_uint16_t nodeid;
  nx_uint16_t rssi;
  nx_uint16_t light;
} RssiDistMsg;

#endif //DEFINITIONS_H__
