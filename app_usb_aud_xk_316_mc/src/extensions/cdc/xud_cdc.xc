// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xs1.h>
#include <stdio.h>
#include <string.h>
#include "xud.h"                 /* XUD user defines and functions */
#include "usb_std_requests.h"
#include "usb_std_descriptors.h"
#include "xud_cdc.h"
#include "cdc_descriptor_defs.h"


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
