# VHDL-Graphics-Card
A very simple VGA Graphics Card using VHDL

This is actually not a Graphics Card, rather than a Graphics Output from an FPGA via VGA.
If you put a VGA female output on a breakout-board and connect a monitor to it, you will see a square or a dot,
moving around and bouncing of off the screen's edges.

#Usage
The project can be configured in the generic of the basicVGA entity. The initX and Y are the inital position of the object bouncing around.
The origin of coordinates is the top left corner. The initialXdir and Y are the initial moving direction of the object. 1 means positive and 0 negative
increment. 

The internal Clock of the FPGA must be 12MHz. Otherwise the code has to be adjusted. The resolution is 800x600 with a 35.15625kHz refresh rate.
The numbers for the internal Clock skip doesn't add up perfectly and skips one pixel, this is however negligible.

Theoretically a external Clock with 12MHz can be used. CLK is defined as an input port.

HSYNC
VSYNC
R
G
B
are defined as outputs and should be forwared to the VGA breakout-board. Keep in mind, you will have to use voltage deviders to achieve the 0,7V for R,G and B.
Scale these with the logic level voltage of your FPGA (3,3V or 5V). A pulldown resistor for HSYNC and VSYNC might be adviseable aswell.

A negated Reset is also defined as an input port, just hook it up to a switch. A pullup resistor in this case is mandatory.
Besides that a "beep" port is also outputted. It goes to high when the object bounces off of a corner. Just hook it up to an active buzzer or leave it as is.

All of the out- and input have to be mapped to designated ports on your FPGA.
