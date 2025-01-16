
# CSE 30342 - Digital Integrated Circuits - University of Notre Dame



## Group Members
Daniel Noronha - dnoronha@nd.edu  
Ricky Ortiz - rortiz4@nd.edu  
Nguyen Nguyen - nnguye24@nd.edu  

## Fan Speed Controller Final Project Verilog and Tapeout
![fanspeedcontrollerCaravel](https://github.com/user-attachments/assets/d92ee705-f592-45e1-8dfc-4d2500abaec3)

## See gds files in caravel-files for tapeout
## Detailed Project Description
This project consists of controller and datapath modules for a top-level fan_speed_controller Finite State Machine Module.  
It also contains a testbench that can be used with xrun for behavioral simulations of the fan speed controller.  

The fan speed controller uses the setpoint temperature and current temperature to turn on a fan and adjust its speed.  
After speed adjustment, it waits for a reset signal (high) before evaluating the fan speed again based on new temperature readings/setpoints.  

Speed adjustments are based on modifiable controller module parameters for thresholds above the setpoint.  
For example:  
Fan Off => Low is triggered at 0 degrees F above setpoint (fan is off always at/below setpoint).  
Fan Low => Med is triggered at 5 degrees F above setpoint.  
Fan Med => High is triggered at 10 degrees F above setpoint.  

A manual override mode is also included. If manual_override is set to 1, override_speed is used to decide whether the fan
is overridden to OFF or MAX speed (finer speed control in override mode not possible due to limited GPIO without sacrificing temp range).

Fan Speed Controller Inputs (16 bits):  
    &nbsp;&nbsp;&nbsp;&nbsp;- clk: Clock Signal  
    &nbsp;&nbsp;&nbsp;&nbsp;- reset: Reset Signal used to trigger reevaluation of state  
    &nbsp;&nbsp;&nbsp;&nbsp;- temperature_reading: 7-bit temperature reading in Farenheit from 0-127 (e.g. from an external temperature sensor)  
    &nbsp;&nbsp;&nbsp;&nbsp;- temperature_setpoint: 7-bit temperature setpoint in Farenheit from 0-127 (e.g. from user input/microcontroller)  
    &nbsp;&nbsp;&nbsp;&nbsp;- manual_override: 1-bit override flag to enable manual override of fan speed  
    &nbsp;&nbsp;&nbsp;&nbsp;- override_speed: 1-bit flag to choose whether fan speed is max or fan is off in override mode  

Fan Speed Controller Outputs (6 bits):  
    &nbsp;&nbsp;&nbsp;&nbsp;- speed_set: Signals when the fan speed output is valid for subsequent control device (has been set correctly after reset).  
    &nbsp;&nbsp;&nbsp;&nbsp;- current_fan_speed: 2-bit; output to fan/cooling system or DAC attached to the fan/cooling system (final system output)  
    &nbsp;&nbsp;&nbsp;&nbsp;- current_state: 3-bit; just provieded for reference, to know the current state of the fan speed controller  

Finite State Machine (FSM) States (7 total):  
    &nbsp;&nbsp;&nbsp;&nbsp;- evaluating_fan_speed = 3'b000; Initial state and state entered after reset is pulled high (reset=1)  
    &nbsp;&nbsp;&nbsp;&nbsp;- fan_speed_off = 3'b001; Fan off state if temperature too low or while evaluating the temperature after reset  
    &nbsp;&nbsp;&nbsp;&nbsp;- fan_speed_low = 3'b010; Fan low state if temperature between setpoint and off_low_threshold  
    &nbsp;&nbsp;&nbsp;&nbsp;- fan_speed_med = 3'b011; Fan med state if temperature between setpoint and low_med_threshold  
    &nbsp;&nbsp;&nbsp;&nbsp;- fan_speed_high = 3'b100; Fan high state if temperature between setpoint and med_high_threshold  
    &nbsp;&nbsp;&nbsp;&nbsp;- fan_speed_override_off = 3'b101; Fan off state by manual override  
    &nbsp;&nbsp;&nbsp;&nbsp;- fan_speed_override_max = 3'b110; Fan on state (max speed) by manual override  

Allowed Fan Speeds (4):  
    &nbsp;&nbsp;&nbsp;&nbsp;- Off: In Normal OR Override States  
    &nbsp;&nbsp;&nbsp;&nbsp;- Low: In Normal State Only  
    &nbsp;&nbsp;&nbsp;&nbsp;- Medium (Med): In Normal State Only  
    &nbsp;&nbsp;&nbsp;&nbsp;- High: In Normal OR Override States  

Modules:  
    &nbsp;&nbsp;&nbsp;&nbsp;- fan_speed_controller: Top level module connecting fan_speed_controller_controller and fan_speed_controller_datapath  
    &nbsp;&nbsp;&nbsp;&nbsp;- fan_speed_controller_controller: This module accepts temperature/override state data as input and outputs a new state using it.  
    &nbsp;&nbsp;&nbsp;&nbsp;- fan_speed_controller_datapath: This module accpets state data from the controller and sets fan speeds (+speed_set signal) accordingly.  
    &nbsp;&nbsp;&nbsp;&nbsp;- fan_speed_controller_testbench: Testbench module for the fan_speed_controller to apply stimulus and observe behavioral response of DUT.  
    

