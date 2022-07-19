import tm1637
import gpio

main:

    // Set clock and data pins as output
    pinCLK := gpio.Pin 22 --output
    pinDIO := gpio.Pin 23 --output

    // Initialize display and set the brightness as 7 (max)
    disp := tm1637.Tm1637 pinCLK pinDIO
    disp.setBrightness 7

    while true:
        now := Time.now.utc // Get the current UTC time

        time := now.h * 100 + now.m // Put hours and minutes together as a 4-digit number to make it easy to display
        s := now.s

        // Display dots every alternate second
        if s%2 == 0:
            disp.showNumber time --leading_zero --show_dots
        else:
            disp.showNumber time --leading_zero

        sleep --ms=1