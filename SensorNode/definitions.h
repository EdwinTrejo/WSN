#ifndef DEFINITIONS_H__
#define DEFINITIONS_H__

#define NEW_PRINTF_SEMANTICS

#include "Timer.h"
#include "printf.h"

#define ROBOT_MOTE 0
#define GATEWAY_MOTE 1

typedef nx_struct LightMsg {
	nx_uint16_t nodeid;
  nx_uint16_t light;
} LightMsg;

#endif //DEFINITIONS_H__
