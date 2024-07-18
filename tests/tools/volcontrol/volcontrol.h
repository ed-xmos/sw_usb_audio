#ifndef _volcontrol_h_
#include "volcontrol_impl.h"

#include <cstdint>

enum operation {
  NONE,
  RESET_ALL,
  SET_VOLUME,
  SHOW_ALL,
  SET_CLOCK,
  SHOW_STREAM_FORMATS,
  SET_STREAM_FORMAT,
  SHOW_CURRENT_STREAM_FORMAT,
  SET_FULL_STREAM_FORMAT
};

enum scope {
  ScopeOutput,
  ScopeInput
};


#ifdef _WIN32
// GUID strings are 36 characters, plus a pair of braces and NUL-termination
#define GUID_STR_LEN (36+2+1)
AudioDeviceHandle getXMOSDeviceID(TCHAR guid[GUID_STR_LEN]);
#else
AudioDeviceHandle getXMOSDeviceID();
#endif

float getVolume(AudioDeviceHandle deviceID, uint32_t scope, uint32_t channel);

void setVolume(AudioDeviceHandle deviceID, uint32_t scope,
	       uint32_t channel, float volume);

void setClock(AudioDeviceHandle deviceID, uint32_t clockId);

void showStreamFormats(AudioDeviceHandle deviceID);

void setStreamFormat(AudioDeviceHandle deviceID, uint32_t scope, unsigned sample_rate, unsigned num_chans, unsigned bit_depth);

void showCurrentStreamFormat(AudioDeviceHandle deviceID);

void setFullStreamFormat(AudioDeviceHandle deviceID, unsigned sample_rate,
                         unsigned in_num_chans, unsigned in_bit_depth,
                         unsigned out_num_chans, unsigned out_bit_depth);

void finish(void);
#endif  // _volcontrol_h_
