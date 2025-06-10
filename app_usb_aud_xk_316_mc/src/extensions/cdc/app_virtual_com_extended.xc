// Copyright (c) 2015, XMOS Ltd, All rights reserved

#if CDC_VSP

#include <platform.h>
#include <xs1.h>
#include <stdio.h>
#include <string.h>
#include <timer.h>
// #include "i2c_lib.h"
#include "xud_cdc.h"

/* App specific defines */
#define MENU_MAX_CHARS  50
#define MENU_LIST       11
#define DEBOUNCE_TIME   (XS1_TIMER_HZ/50)
#define BUTTON_PRESSED  0x00

// FXOS8700EQ register address defines - From AN00181
#define FXOS8700EQ_I2C_ADDR 0x1E
#define FXOS8700EQ_XYZ_DATA_CFG_REG 0x0E
#define FXOS8700EQ_CTRL_REG_1 0x2A
#define FXOS8700EQ_DR_STATUS 0x0
#define FXOS8700EQ_OUT_X_MSB 0x1
#define FXOS8700EQ_OUT_X_LSB 0x2
#define FXOS8700EQ_OUT_Y_MSB 0x3
#define FXOS8700EQ_OUT_Y_LSB 0x4
#define FXOS8700EQ_OUT_Z_MSB 0x5
#define FXOS8700EQ_OUT_Z_LSB 0x6

/* PORT_4A connected to the 4 LEDs */
on tile[0]: port p_led = XS1_PORT_4F;

/* PORT_4C connected to the 2 Buttons */
on tile[0]: port p_button = XS1_PORT_4E;

char app_menu[MENU_LIST][MENU_MAX_CHARS] = {
        {"\n\r-----------------------------------\r\n"},
        {"XMOS USB Audio and Virtual COM Demo\r\n"},
        {"-----------------------------------\r\n"},
        {"0. Toggle LED 0\r\n"},
        {"1. Toggle LED 1\r\n"},
        {"2. Toggle LED 2\r\n"},
        {"3. Toggle LED 3\r\n"},
        {"4. Switch to Echo mode\r\n"},
        {"5. Print timer ticks\r\n"},
        {"-----------------------------------\r\n"},
};

char echo_mode_str[3][30] = {
        {"Entered echo mode\r\n"},
        {"Press Ctrl+Z to exit it\r\n"},
        {"\r\nExit echo mode\r\n"},
};

#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))

/* Sends out the App menu over CDC virtual port*/
void show_menu(client interface usb_cdc_interface cdc)
{
    unsigned length;
    for(int i = 0; i < MENU_LIST; i++) {
        length = strlen(app_menu[i]);
        cdc.write(app_menu[i], length);
    }
}

/* Function to set LED state - ON/OFF */
void set_led_state(int led_id, int val)
{
  int value;
  /* Read port value into a variable */
  p_led :> value;
  if (!val) {
      p_led <: (value | (1 << led_id));
  } else {
      p_led <: (value & ~(1 << led_id));
  }
}

/* Function to toggle LED state */
void toggle_led(int led_id)
{
    int value;
    p_led :> value;
    p_led <: (value ^ (1 << led_id));
}

/* Function to get button state (0 or 1)*/
int get_button_state(int button_id)
{
    int button_val;
    p_button :> button_val;
    button_val = (button_val >> button_id) & (0x01);
    return button_val;
}

/* Checks if a button is pressed */
int is_button_pressed(int button_id)
{
    if(get_button_state(button_id) == BUTTON_PRESSED) {
        /* Wait for debounce and check again */
        delay_ticks(DEBOUNCE_TIME);
        if(get_button_state(button_id) == BUTTON_PRESSED) {
            return 1; /* Yes button is pressed */
        }
    }
    /* No button press */
    return 0;
}


/* Application task */
void app_virtual_com_extended(client interface usb_cdc_interface cdc)
{
    unsigned int length, led_id;
    char value, tmp_string[50];
    timer tmr;
    unsigned int timer_val;

    /* Set all LEDs to OFF (Active high)*/
    p_led <: 0x00;
    show_menu(cdc);

    unsigned button_valid[3] = {1, 1, 1};

    while(1)
    {
        /* Check for a change in buttons - Detects 1->0 transition */
        for(int button_id = 0; button_id < 3; button_id++){
            if(is_button_pressed(button_id)) {
                if(button_valid[button_id]) {
                    button_valid[button_id] = 0;
                    length = sprintf(tmp_string, "\r\nButton %d Pressed!\n", button_id);
                    cdc.write(tmp_string, length);
                }
            } else {
                button_valid[button_id] = 1;
            }
        }

        /* Check if user has input any character */
        if(cdc.available_bytes())
        {
            value = cdc.get_char();

            /* Do the chosen operation */
            if((value >= '0') && (value <= '3')) {
                /* Find out which LED to toggle */
                led_id = (value - 0x30);    // 0x30 used to convert the ascii to number
                toggle_led(led_id);
            }
            else if(value == '4') {
                length = strlen(echo_mode_str[0]);
                cdc.write(echo_mode_str[0], length);
                length = strlen(echo_mode_str[1]);
                cdc.write(echo_mode_str[1], length);

                while(value != 0x1A) { /* 0x1A = Ctrl + Z */
                    value = cdc.get_char();
                    cdc.put_char(value);
                }
                length = strlen(echo_mode_str[2]);
                cdc.write(echo_mode_str[2], length);
            }
            else if(value == '5') {
                /* Read 32-bit timer value */
                tmr :> timer_val;
                length = sprintf(tmp_string, "Timer ticks: %u\r\n", timer_val);
                cdc.write(tmp_string, length);
            }
            else {
                show_menu(cdc);
            }
        }
    } /* end of while(1) */
}

#endif