// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef CDC_DESCRIPTOR_DEFS_H_
#define CDC_DESCRIPTOR_DEFS_H_

/* USB Sub class and protocol codes */
#define USB_CDC_ACM_SUBCLASS        0x02
#define USB_CDC_AT_COMMAND_PROTOCOL 0x01

/* CDC interface descriptor type */
#define USB_DESCTYPE_CS_INTERFACE   0x24

/* Data endpoint packet size */
#define MAX_EP_SIZE     512

/* CDC Communications Class requests */
#define CDC_SET_LINE_CODING         0x20
#define CDC_GET_LINE_CODING         0x21
#define CDC_SET_CONTROL_LINE_STATE  0x22
#define CDC_SEND_BREAK              0x23


#endif /* CDC_DESCRIPTOR_DEFS_H_ */
