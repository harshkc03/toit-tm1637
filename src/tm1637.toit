// Copyright (C) 2021 Harsh Chaudhary. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import gpio

// Driver class for the TM1637 4-digit 7-segment display
class Tm1637:

    // Two-wire I2C like communication
    clock_/gpio.Pin
    data_/gpio.Pin

    //
    //      A
    //     ---
    //  F |   | B
    //     -G-
    //  E |   | C
    //     ---
    //      D
    digitToSegment := [
        //XGFEDCBA
        0b00111111,    // 0
        0b00000110,    // 1
        0b01011011,    // 2
        0b01001111,    // 3
        0b01100110,    // 4
        0b01101101,    // 5
        0b01111101,    // 6
        0b00000111,    // 7
        0b01111111,    // 8
        0b01101111,    // 9
        0b01110111,    // A
        0b01111100,    // b
        0b00111001,    // C
        0b01011110,    // d
        0b01111001,    // E
        0b01110001     // F
    ]

    constructor .clock_ .data_:

        // Configure clock and data pins as output
        clock_.config --output
        data_.config --output

        // Clear the display
        clear
    
    // Start the transmission to TM1637
    start:
        clock_.set 1
        data_.set 1

        data_.set 0
        clock_.set 0 
    
    // Stop the transmission to TM1637
    stop:
        clock_.set 0
        data_.set 0
        
        clock_.set 1
        data_.set 1
    
    // Write the given 8-bit value to the chip and receive the acknowledgement
    writeValue byte:

        // Write 8 bits one by one by pulling the clock low
        8.repeat:
            clock_.set 0

            bit := byte & 1
            byte >>= 1
            data_.set bit

            clock_.set 1
        
        // Receive the ackownledgement, although we won't use it
        clock_.set 0
        data_.config --input
        clock_.set 1
        ack := data_.get
        data_.config --output
    
    // Set the values of the 4 digits individually
    write first second third fourth --show_dots/bool = false:

        start
        writeValue 0x40 // Write CmdSetData (0x40)
        stop

        if show_dots:
            second |= 0x80

        start
        writeValue 0xc0 //Write CmdSetAddress (0xc0)
        writeValue first
        writeValue second
        writeValue third
        writeValue fourth
        stop
    
    // Display any integer value (0 - 9999), and set whether leading zeroes and dots are to be displayed
    showNumber num --leading_zero/bool = false --show_dots/bool = false:
        digits := [0x00, 0x00, 0x00, 0x00]

        // Break the number into individual digits and write them
        4.repeat:
            digit := num % 10

            if digit == 0 and num == 0 and not leading_zero:
                digits[4-it-1] = 0x00
            else:
                digits[4-it-1] = digitToSegment[digit & 0x0f]

            num /= 10

        write digits[0] digits[1] digits[2] digits[3] --show_dots=show_dots
    
    // Set brightness of the screen (0 - 7). Setting to zero turns it off
    setBrightness brightness:
        brightness = brightness == 0 ? 0x80 : 0x88 | brightness // Wirte CmdDisplay (0x80) and brightness value

        start
        writeValue brightness
        stop
    
    // Clear the display completely or just display 4 zeroes
    clear --with_zeroes/bool=false:
        if with_zeroes:
            write 0x3f 0x3f 0x3f 0x3f
        else:
            write 0x00 0x00 0x00 0x00