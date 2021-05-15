#ifndef DEFINITIONS_H__
#define DEFINITIONS_H__

#define NEW_PRINTF_SEMANTICS

#include "Timer.h"
#include "printf.h"

// sampling frequency in binary milliseconds
#define SAMPLING_FREQUENCY 100

#define ROBOT_MOTE 0
#define GATEWAY_MOTE 1

enum {
	AM_DEMO_MESSAGE = 150,
};

typedef nx_struct LightMsg {
	nx_uint16_t nodeid;
  nx_uint16_t light;
} LightMsg;

#endif //DEFINITIONS_H__
