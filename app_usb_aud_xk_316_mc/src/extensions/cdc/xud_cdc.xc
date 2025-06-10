// Copyright (c) 2015, XMOS Ltd, All rights reserved

#include <xs1.h>
#include <stdio.h>
#include <string.h>
//#include "usb.h"
#include "xud.h"                 /* XUD user defines and functions */
#include "usb_std_requests.h"
#include "usb_std_descriptors.h"
#include "xud_cdc.h"
#include "cdc_descriptor_defs.h"

#if 0 // These descriptors were merged with those in descriptors.h
/* Definition of Descriptors */
/* USB Device Descriptor */
static unsigned char devDesc[] =
{
    0x12,                  /* 0  bLength */
    USB_DESCTYPE_DEVICE,   /* 1  bdescriptorType - Device*/
    0x00,                  /* 2  bcdUSB version */
    0x02,                  /* 3  bcdUSB version */
    USB_CLASS_COMMUNICATIONS,/* 4  bDeviceClass - USB CDC Class */
    0x00,                  /* 5  bDeviceSubClass  - Specified by interface */
    0x00,                  /* 6  bDeviceProtocol  - Specified by interface */
    0x40,                  /* 7  bMaxPacketSize for EP0 - max = 64*/
    (VENDOR_ID & 0xFF),    /* 8  idVendor */
    (VENDOR_ID >> 8),      /* 9  idVendor */
    (PRODUCT_ID & 0xFF),   /* 10 idProduct */
    (PRODUCT_ID >> 8),     /* 11 idProduct */
    (BCD_DEVICE & 0xFF),   /* 12 bcdDevice */
    (BCD_DEVICE >> 8),     /* 13 bcdDevice */
    0x01,                  /* 14 iManufacturer - index of string*/
    0x02,                  /* 15 iProduct  - index of string*/
    0x03,                  /* 16 iSerialNumber  - index of string*/
    0x01                   /* 17 bNumConfigurations */
};

/* USB Configuration Descriptor */
static unsigned char cfgDesc[] = {

  0x09,                       /* 0  bLength */
  USB_DESCTYPE_CONFIGURATION, /* 1  bDescriptortype - Configuration*/
  0x43, 0x00,                 /* 2  wTotalLength */
  0x02,                       /* 4  bNumInterfaces */
  0x01,                       /* 5  bConfigurationValue */
  0x04,                       /* 6  iConfiguration - index of string */
  0x80,                       /* 7  bmAttributes - Bus powered */
  0xC8,                       /* 8  bMaxPower - 400mA */

  /* CDC Communication interface */
  0x09,                       /* 0  bLength */
  USB_DESCTYPE_INTERFACE,     /* 1  bDescriptorType - Interface */
  0x00,                       /* 2  bInterfaceNumber - Interface 0 */
  0x00,                       /* 3  bAlternateSetting */
  0x01,                       /* 4  bNumEndpoints */
  USB_CLASS_COMMUNICATIONS,   /* 5  bInterfaceClass */
  USB_CDC_ACM_SUBCLASS,       /* 6  bInterfaceSubClass - Abstract Control Model */
  USB_CDC_AT_COMMAND_PROTOCOL,/* 7  bInterfaceProtocol - AT Command V.250 protocol */
  0x00,                       /* 8  iInterface - No string descriptor */

  /* Header Functional descriptor */
  0x05,                      /* 0  bLength */
  USB_DESCTYPE_CS_INTERFACE, /* 1  bDescriptortype, CS_INTERFACE */
  0x00,                      /* 2  bDescriptorsubtype, HEADER */
  0x10, 0x01,                /* 3  bcdCDC */

  /* ACM Functional descriptor */
  0x04,                      /* 0  bLength */
  USB_DESCTYPE_CS_INTERFACE, /* 1  bDescriptortype, CS_INTERFACE */
  0x02,                      /* 2  bDescriptorsubtype, ABSTRACT CONTROL MANAGEMENT */
  0x02,                      /* 3  bmCapabilities: Supports subset of ACM commands */

  /* Union Functional descriptor */
  0x05,                     /* 0  bLength */
  USB_DESCTYPE_CS_INTERFACE,/* 1  bDescriptortype, CS_INTERFACE */
  0x06,                     /* 2  bDescriptorsubtype, UNION */
  0x00,                     /* 3  bControlInterface - Interface 0 */
  0x01,                     /* 4  bSubordinateInterface0 - Interface 1 */

  /* Call Management Functional descriptor */
  0x05,                     /* 0  bLength */
  USB_DESCTYPE_CS_INTERFACE,/* 1  bDescriptortype, CS_INTERFACE */
  0x01,                     /* 2  bDescriptorsubtype, CALL MANAGEMENT */
  0x03,                     /* 3  bmCapabilities, DIY */
  0x01,                     /* 4  bDataInterface */

  /* Notification Endpoint descriptor */
  0x07,                         /* 0  bLength */
  USB_DESCTYPE_ENDPOINT,        /* 1  bDescriptorType */
  (CDC_NOTIFICATION_EP_NUM | 0x80),/* 2  bEndpointAddress */
  0x03,                         /* 3  bmAttributes */
  0x40,                         /* 4  wMaxPacketSize - Low */
  0x00,                         /* 5  wMaxPacketSize - High */
  0xFF,                         /* 6  bInterval */

  /* CDC Data interface */
  0x09,                     /* 0  bLength */
  USB_DESCTYPE_INTERFACE,   /* 1  bDescriptorType */
  0x01,                     /* 2  bInterfacecNumber */
  0x00,                     /* 3  bAlternateSetting */
  0x02,                     /* 4  bNumEndpoints */
  USB_CLASS_CDC_DATA,       /* 5  bInterfaceClass */
  0x00,                     /* 6  bInterfaceSubClass */
  0x00,                     /* 7  bInterfaceProtocol*/
  0x00,                     /* 8  iInterface - No string descriptor*/

  /* Data OUT Endpoint descriptor */
  0x07,                     /* 0  bLength */
  USB_DESCTYPE_ENDPOINT,    /* 1  bDescriptorType */
  CDC_DATA_RX_EP_NUM,       /* 2  bEndpointAddress */
  0x02,                     /* 3  bmAttributes */
  0x00,                     /* 4  wMaxPacketSize - Low */
  0x02,                     /* 5  wMaxPacketSize - High */
  0x00,                     /* 6  bInterval */

  /* Data IN Endpoint descriptor */
  0x07,                     /* 0  bLength */
  USB_DESCTYPE_ENDPOINT,    /* 1  bDescriptorType */
  (CDC_DATA_TX_EP_NUM | 0x80),/* 2  bEndpointAddress */
  0x02,                     /* 3  bmAttributes */
  0x00,                     /* 4  wMaxPacketSize - Low byte */
  0x02,                     /* 5  wMaxPacketSize - High byte */
  0x01                      /* 6  bInterval */
};

unsafe{
  /* String table - unsafe as accessed via shared memory */
  static char * unsafe stringDescriptors[]=
  {
    "\x09\x04",             /* Language ID string (US English) */
    "XMOS",                 /* iManufacturer */
    "CDC Virtual COM Port", /* iProduct */
    "0123456789"            /* iSerialNumber */
    "Config",               /* iConfiguration string */
  };
}
#endif

/* CDC Class-specific requests handler function */
XUD_Result_t ControlInterfaceClassRequests(XUD_ep ep_out, XUD_ep ep_in, USB_SetupPacket_t sp)
{
    /* Word aligned buffer */
    unsigned int buffer[32];
    unsigned length;
    XUD_Result_t result;

    static struct LineCoding {
        unsigned int baudRate;
        unsigned char charFormat;
        unsigned char parityType;
        unsigned char dataBits;
    }lineCoding;

    static struct lineState {
        unsigned char dtr;
        unsigned char rts;
    } lineState;


    switch(sp.bRequest)
    {
        case CDC_SET_LINE_CODING:

            if((result = XUD_GetBuffer(ep_out, (buffer, unsigned char[]), length)) != XUD_RES_OKAY)
            {
                return result;
            }

            lineCoding.baudRate = buffer[0];    /* Read 32-bit baud rate value */
            lineCoding.charFormat = (buffer, unsigned char[])[4]; /* Read one byte */
            lineCoding.parityType = (buffer, unsigned char[])[5];
            lineCoding.dataBits = (buffer, unsigned char[])[6];

            result = XUD_DoSetRequestStatus(ep_in);

            #if defined (CDC_DEBUG) && (CDC_DEBUG == 1)
            printf("Baud rate: %u\n", lineCoding.baudRate);
            printf("Char format: %d\n", lineCoding.charFormat);
            printf("Parity Type: %d\n", lineCoding.parityType);
            printf("Data bits: %d\n", lineCoding.dataBits);
            #endif
            return result;

            break;

        case CDC_GET_LINE_CODING:

            buffer[0] = lineCoding.baudRate;
            (buffer, unsigned char[])[4] = lineCoding.charFormat;
            (buffer, unsigned char[])[5] = lineCoding.parityType;
            (buffer, unsigned char[])[6] = lineCoding.dataBits;

            return XUD_DoGetRequest(ep_out, ep_in, (buffer, unsigned char[]), 7, sp.wLength);

            break;

        case CDC_SET_CONTROL_LINE_STATE:

            /* Data present in wValue */
            lineState.dtr = sp.wValue & 0x01;
            lineState.rts = (sp.wValue >> 1) & 0x01;

            /* Acknowledge */
            result =  XUD_DoSetRequestStatus(ep_in);

            #if defined (CDC_DEBUG) && (CDC_DEBUG == 1)
            printf("DTR: %d\n", lineState.dtr);
            printf("RTS: %d\n", lineState.rts);
            #endif

            return result;

            break;

        case CDC_SEND_BREAK:
            /* Send break signal on UART (if requried) */
            // sp.wValue says the number of milliseconds to hold in BREAK condition
            return XUD_DoSetRequestStatus(ep_in);

            break;

        default:
            // Error case
            printhexln(sp.bRequest);
            break;
    }
    return XUD_RES_ERR;
}


/* Function to handle all endpoints of the CDC class excluding control endpoint0 */
void CdcEndpointsHandler(chanend c_epint_in, chanend c_epbulk_out, chanend c_epbulk_in,
                         SERVER_INTERFACE(usb_cdc_interface, cdc))
{
    static unsigned char txBuf[2][MAX_EP_SIZE];
    static unsigned char rxBuf[2][MAX_EP_SIZE];
    int readBufId = 0, writeBufId = 0;          // used to identify buffer read/write by device
    int rxLen[2] = {0, 0}, txLen = 0;
    int readIndex = 0;
    int readWaiting = 0, writeWaiting = 1;

    unsigned length;
    XUD_Result_t result;

    /* Initialize all endpoints */
    XUD_ep epint_in = XUD_InitEp(c_epint_in);
    XUD_ep epbulk_out = XUD_InitEp(c_epbulk_out);
    XUD_ep epbulk_in = XUD_InitEp(c_epbulk_in);

    /* XUD will NAK if the endpoint is not ready to communicate with XUD */

    /* TODO: Interrupt endpoint to report serial state (if required) */

    /* Just to keep compiler happy */
    epint_in = epint_in;

    XUD_SetReady_Out(epbulk_out, rxBuf[!readBufId]);
    //XUD_SetReady_In???


    while(1)
    {
      select
      {
        case XUD_GetData_Select(c_epbulk_out, epbulk_out, length, result):   
           if(result == XUD_RES_OKAY)
           {
               /* Received some data */
               rxLen[!readBufId] = length;

               /* Check if application has completed reading the read buffer */
               if(rxLen[readBufId] == 0) {
                   /* Switch buffers */
                   readBufId = !readBufId;
                   readIndex = 0;
                   /* Make the OUT endpoint ready to receive data */
                   XUD_SetReady_Out(epbulk_out, rxBuf[!readBufId]);
               } else {
                   /* Application is still reading the read buffer
                    * Say that another buffer is also waiting to be read */
                   readWaiting = 1;
               }
           } else {
               XUD_SetReady_Out(epbulk_out, rxBuf[!readBufId]);
           }
           break;

        case XUD_SetData_Select(c_epbulk_in, epbulk_in, result):
            /* Packet sent successfully when result in XUD_RES_OKAY */
            if (0 != txLen) {
                /* Data available to send to Host */
                XUD_SetReady_In(epbulk_in, txBuf[writeBufId], txLen);
                /* Switch write buffers */
                writeBufId = !writeBufId;
                txLen = 0;
            } else {
                writeWaiting = 1;
            }

            break;

        /* Case handlers for CDC functions */
        case (0 != rxLen[readBufId]) => cdc.read(unsigned char data[], REFERENCE_PARAM(unsigned, count)) -> int read_count:
            /* Some data available to read */
            if(count <= rxLen[readBufId]) {
                /* Read only 'count' number of bytes */
                memcpy(data, rxBuf[readBufId]+readIndex, count);
                read_count = count;
                readIndex += count;
                rxLen[readBufId] -= count;

            } else if(count > rxLen[readBufId]) {
                /* Read all bytes from buffer */
                memcpy(data, rxBuf[readBufId]+readIndex, rxLen[readBufId]);
                read_count = rxLen[readBufId];
                rxLen[readBufId] = 0;
                readIndex = 0;
            }

            if(readWaiting && (rxLen[readBufId] == 0)) {
                /* Other buffer is waiting to be read; switch it for reading */
                readBufId = !readBufId;
                readIndex = readWaiting = 0;
                XUD_SetReady_Out(epbulk_out, rxBuf[!readBufId]);
            }
            break;

        case (0 != rxLen[readBufId]) => cdc.get_char() -> unsigned char data:
            /* Read one byte of data */
            data = rxBuf[readBufId][readIndex++];
            rxLen[readBufId]--;

            if(readWaiting && (rxLen[readBufId] == 0)) {
                /* Other buffer is waiting to be read; switch it for reading */
                readBufId = !readBufId;
                readIndex = readWaiting = 0;
                XUD_SetReady_Out(epbulk_out, rxBuf[!readBufId]);
            }
            break;

        case (MAX_EP_SIZE != txLen) => cdc.put_char(char byte):
            txBuf[writeBufId][txLen] = byte;
            txLen++;

            /* Check if we can initiate transfer */
            if(writeWaiting) {
                XUD_SetReady_In(epbulk_in, txBuf[writeBufId], txLen);
                writeBufId = !writeBufId;
                txLen = 0;
                writeWaiting = 0;
            }
            break;

        case (MAX_EP_SIZE != txLen) => cdc.write(unsigned char data[], REFERENCE_PARAM(unsigned, length)) -> int write_count:

            if((txLen + length) <= MAX_EP_SIZE) {
                /* Enough space available to hold all data */
                write_count = length;
            } else {
                /* Only partial data can be put into buffer */
                write_count = MAX_EP_SIZE - txLen;
            }
            memcpy(txBuf[writeBufId] + txLen, data, write_count);
            txLen += write_count;

            /* Check if we can initiate transfer */
            if(writeWaiting) {
                XUD_SetReady_In(epbulk_in, txBuf[writeBufId], txLen);
                writeBufId = !writeBufId;
                txLen = 0;
                writeWaiting = 0;
            }
            break;

        case cdc.available_bytes() -> int count:
            count = rxLen[readBufId];
            break;

        case cdc.flush_buffer():

            /* Flush everything */
            rxLen[readBufId] = 0;
            readIndex = 0;

            if(readWaiting) {
                /* Other buffer is ready to be read, flush that too */
                readBufId = !readBufId;
                rxLen[readBufId] = 0;
                readWaiting = 0;
                XUD_SetReady_Out(epbulk_out, rxBuf[!readBufId]);
            }
            break;
      }
    }

}
