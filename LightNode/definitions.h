#ifndef DEFINITIONS_H__
#define DEFINITIONS_H__

#define NEW_PRINTF_SEMANTICS

// sampling frequency in binary milliseconds
#define SAMPLING_FREQUENCY 100

#include "Timer.h"
#include "printf.h"

enum {
  AM_RSSIMSG = 10
};

typedef nx_struct RssiMsg{
  nx_int16_t rssi;
} RssiMsg;

enum {
  SEND_INTERVAL_MS = 10000
};

enum {
  TIME_INTERVAL = 500
};

#endif //DEFINITIONS_H__
