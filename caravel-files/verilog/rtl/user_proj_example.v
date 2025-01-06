/*************************************
 * Modified by: Daniel Noronha, Ricky Ortiz, Nguyen Nguyen
 * Date: 12/11/2024
 * Email: dnoronha@nd.edu
 * 
 * This file contains the modified user_proj_example file provided by
 * EFabless for connecting to the Caravel Harness.
 *************************************/


module user_proj_example (
`ifdef USE_POWER_PINS
    inout vdd,	// User area 1 1.8V supply
    inout vss,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,

    // IOs
    input  [15:0] io_in,
    output [5:0] io_out,
    output [5:0] io_oeb
);
    // Mapping clk and reset wires
    wire clk = wb_clk_i;
    wire rst = !wb_rst_i;

    // Set io_oeb to 0 to ensure outputs are always on
    assign io_oeb = 6'b0;

    // Wires to input signals
    // wire [6:0] temperature_reading;
    // wire [6:0] temperature_setpoint;
    // wire manual_override;
    // wire override_speed;

    // Wires to output signals
    wire speed_set;
    wire [1:0] current_fan_speed;
    wire [2:0] current_state;

    // Mapping to input wires
    // assign io_in[6:0] = temperature_reading; // 7 bits
    // assign io_in[13:7] = temperature_setpoint; // 7 bits
    // assign io_in[14] = manual_override;
    // assign io_in[15] = override_speed;



    // Instantiate Project Module
    fan_speed_controller fan_speed_controller0(
        .clk(clk),
        .reset(rst),
        .temperature_reading(io_in[6:0]),
        .temperature_setpoint(io_in[13:7]),
        .manual_override(io_in[14]),
        .override_speed(io_in[15]),
        .speed_set(speed_set),
        .current_fan_speed(current_fan_speed),
        .current_state(current_state)
    );

    // Mapping to output wires
    assign io_out[0] = speed_set;
    assign io_out[2:1] = current_fan_speed; // 2 bits
    assign io_out[5:3] = current_state; // 3 bits


endmodule

/* CSE 30342 Final Project

Group Members:
    - Daniel Noronha: dnoronha@nd.edu
    - Ricky Ortiz: rortiz4@nd.edu
    - Nguyen Nguyen: nnguye24@nd.edu

This project consists of controller and datapath modules for a top-level fan_speed_controller Finite State Machine Module.
It also contains a testbench that can be used with xrun for behavioral simulations of the fan speed controller.

The fan speed controller uses the setpoint temperature and current temperature to turn on a fan and adjust its speed.
Speed adjustments are based on modifiable controller module parameters for thresholds above the setpoint. For example, 
Fan Off=>Low is triggered at 0 degrees F above setpoint (fan is off always below setpoint).
Fan Low=>Med is triggered at 5 degrees F above setpoint
Fan Med=>High is triggered at 10 degrees F above setpoint

A manual override mode is also included. If manual_override is set to 1, override_speed is used to decide whether the fan
is overridden to OFF or MAX speed (finer speed control in override not possible due to limited GPIO without sacrificing temp range).

Fan Speed Controller Inputs (16 bits):
    - clk: Clock Signal
    - reset: Reset Signal used to trigger reevaluation of state
    - temperature_reading: 7-bit temperature reading in Farenheit from 0-127 (e.g. from an external temperature sensor)
    - temperature_setpoint: 7-bit temperature setpoint in Farenheit from 0-127 (e.g. from user input/microcontroller)
    - manual_override: 1-bit override flag to enable manual override of fan speed
    - override_speed: 1-bit flag to choose whether fan speed is max or fan is off in override mode

Fan Speed Controller Outputs (6 bits):
    - speed_set: Signals when the fan speed output is valid for subsequent control device (has been set correctly after reset).
    - current_fan_speed: 2-bit Output to fan/cooling system or DAC attached to the fan/cooling system (final system output)
    - current_state: 3-bit Just provided for reference, to know the current state of the fan speed controller

Finite State Machine (FSM) States (7 total):
    - evaluating_fan_speed = 3'b000; // Initial state and state entered after reset is pulled high (reset=1)
    - fan_speed_off = 3'b001; // Fan off state if temperature too low or while evaluating the temperature after reset
    - fan_speed_low = 3'b010; // Fan low state if temperature between setpoint and off_low_threshold
    - fan_speed_med = 3'b011; // Fan med state if temperature between setpoint and low_med_threshold
    - fan_speed_high = 3'b100; // Fan high state if temperature between setpoint and med_high_threshold
    - fan_speed_override_off = 3'b101; // Fan off state by manual override
    - fan_speed_override_max = 3'b110; // Fan on state (max speed) by manual override

Allowed Fan Speeds (4):
    - Off: In normal OR Override States
    - Low: In Normal State Only
    - Medium (Med): In Normal State Only
    - High: In Normal OR Override States
*/


// This is the top module
module fan_speed_controller(
    input clk,
    input reset,
    input [6:0] temperature_reading,
    input [6:0] temperature_setpoint,
    input manual_override,
    input override_speed,
    output speed_set,
    output [1:0] current_fan_speed,
    output [2:0] current_state
);

    parameter LOW_THRESHOLD = 7'd0; // Degrees Farenheit above setpoint to set fan to low
    parameter MED_THRESHOLD = 7'd5; // Degrees Farenheit above setpoint to set fan to med
    parameter HIGH_THRESHOLD = 7'd10; // Degrees Farenheit above setpoint to set fan to high

    wire [2:0] state_controller_to_datapath_wire;

    fan_speed_controller_controller #(.low_threshold(LOW_THRESHOLD), .med_threshold(MED_THRESHOLD), .high_threshold(HIGH_THRESHOLD)) fan_speed_controller_controller0(
        .clk(clk),
        .reset(reset),
        .temperature_reading(temperature_reading),
        .temperature_setpoint(temperature_setpoint),
        .manual_override(manual_override),
        .override_speed(override_speed),
        .state(state_controller_to_datapath_wire)
    );

    fan_speed_controller_datapath fan_speed_controller_datapath0(
        .clk(clk),
        .state(state_controller_to_datapath_wire),
        .speed_set(speed_set),
        .fan_speed(current_fan_speed),
        .state_info(current_state)
    );

endmodule



// This module sets the FSM state based on temperature readings or manual override (the controller)
module fan_speed_controller_controller #(
    parameter low_threshold = 7'd0, // if temp=setpoint+threshold, fan low
    parameter med_threshold = 7'd5, // if temp=setpoint+threshold, fan med
    parameter high_threshold = 7'd10 // temp=setpoint+threshold, fan high
)
(
    input clk, // Clock Signal (for all sequential logic)
    input reset, // Reset Signal (returns to evaluating_fan_speed state)
    input [6:0] temperature_reading, // Positive Farenheit from a temperature sensor: used to control fan speed (0F to 127F)
    input [6:0] temperature_setpoint, // Desired positive temperature setting in Farenheit (cooling only, no heating, 0F to 127F)
    input manual_override, // Turns on (1) or off (0) override mode to manually turn on or off the fan
    input override_speed, // Use to turn fan on at max speed (1) or off (0)
    output reg [2:0] state // Outputs the current FSM state of the fan speed controller
);

    // Finite State Machine (FSM) States (7)
    localparam evaluating_fan_speed = 3'b000; // Initial state and state entered after reset is pulled high (reset=1)
    localparam fan_speed_off = 3'b001; // Fan off state if temperature too low or while evaluating the temperature after reset
    localparam fan_speed_low = 3'b010; // Fan low state if temperature between setpoint and off_low_threshold
    localparam fan_speed_med = 3'b011; // Fan med state if temperature between setpoint and low_med_threshold
    localparam fan_speed_high = 3'b100; // Fan high state if temperature between setpoint and med_high_threshold
    localparam fan_speed_override_off = 3'b101; // Fan off state by manual override
    localparam fan_speed_override_max = 3'b110; // Fan on state (max speed) by manual override

    reg reset_pulled; // Used to wait for next use of reset pin to re-evaluate fan speed

    initial begin
        state = evaluating_fan_speed;
        reset_pulled = 0;
    end

    always @(posedge clk) begin
        if (reset) begin
            state <= evaluating_fan_speed;
            reset_pulled <= 1;
        end
        else if (reset_pulled && manual_override && (override_speed == 1'b0)) begin
            state <= fan_speed_override_off;
            reset_pulled <= 0;
        end
        else if (reset_pulled && manual_override && (override_speed == 1'b1)) begin
            state <= fan_speed_override_max;
            reset_pulled <= 0;
        end
        else if (reset_pulled && temperature_reading <= temperature_setpoint + low_threshold) begin
            state <= fan_speed_off;
            reset_pulled <= 0;
        end
        else if (reset_pulled && temperature_reading < (temperature_setpoint + med_threshold)) begin
            state <= fan_speed_low;
            reset_pulled <= 0;
        end
        else if (reset_pulled && temperature_reading < (temperature_setpoint + high_threshold)) begin
            state <= fan_speed_med;
            reset_pulled <= 0;
        end
        else if (reset_pulled && temperature_reading >= (temperature_setpoint + high_threshold)) begin
            state <= fan_speed_high;
            reset_pulled <= 0;
        end
        else reset_pulled <= 0; // Unknown state: wait for next reset signal before doing anything.
    end

endmodule

// This datapath module uses the current FSM state to perform the necessary action (set fan speed to off, low, med, or high)
module fan_speed_controller_datapath (input clk, input [2:0] state, output reg speed_set, output reg [1:0] fan_speed, output [2:0] state_info);
    // Finite State Machine (FSM) States (7)
    localparam evaluating_fan_speed = 3'b000; // Initial state and state entered after rst is pulled high (reset=1)
    localparam fan_speed_off = 3'b001; // Fan off state if temperature too low or while evaluating the temperature after reset
    localparam fan_speed_low = 3'b010; // Fan low state if temperature between setpoint and off_low_threshold
    localparam fan_speed_med = 3'b011; // Fan med state if temperature between setpoint and low_med_threshold
    localparam fan_speed_high = 3'b100; // Fan high state if temperature between setpoint and med_high_threshold
    localparam fan_speed_override_off = 3'b101; // Fan off state by manual override
    localparam fan_speed_override_max = 3'b110; // Fan on state (max speed) by manual override

    // Fan Speeds:
    localparam fan_off = 2'b00;
    localparam fan_low = 2'b01;
    localparam fan_med = 2'b10;
    localparam fan_high = 2'b11;

    assign state_info = state; // state_info just passed through to propagate to final output (just for informational purposes)

    initial begin
        fan_speed = fan_off;
        speed_set = 0;
    end

    always @(posedge clk) begin
        case (state)
            evaluating_fan_speed: begin
                fan_speed <= fan_off;
                speed_set <= 0;
            end
            fan_speed_override_off: begin
                fan_speed <= fan_off;
                speed_set <= 1;
            end
            fan_speed_override_max: begin
                fan_speed <= fan_high;
                speed_set <= 1;
            end
            fan_speed_off: begin
                fan_speed <= fan_off;
                speed_set <= 1;
            end
            fan_speed_low: begin
                fan_speed <= fan_low;
                speed_set <= 1;
            end
            fan_speed_med: begin
                fan_speed <= fan_med;
                speed_set <= 1;
            end
            fan_speed_high: begin
                fan_speed <= fan_high;
                speed_set <= 1;
            end
            default: begin
                fan_speed <= fan_off;
                speed_set <= 0; 
            end
        endcase
    end

endmodule


`default_nettype wire
