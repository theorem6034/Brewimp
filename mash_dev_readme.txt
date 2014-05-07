Goals:
Strike water to 168F
Mash Water to 162.6F then to 152F

Routine 1 -  Fire up strike and mash water

Loop 1 - Get strike temp, if over 168F set relay 24V to on if under set relay 24V to off
Loop 2 - Get mash temp, if under 162F set relay 110V to on, if over set relay 110V to off
Event - if loop 1 and loop 2 are off sound buzzer end program

-----------------


Routine 2 - Mash grain
Loop 1 - Get strike temp, if over 168F set relay 24V to on if under set relay 24V to off
Loop 2 - Get mash temp, if under 152F set relay 110V to on, if over set relay 110V to off
Event - set time for 60 minutes, if timer = 0 sound buzzer end program