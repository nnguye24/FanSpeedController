/* CSE 30342 Final Project Testbench

Group Members:
    - Daniel Noronha: dnoronha@nd.edu
    - Ricky Ortiz: rortiz4@nd.edu
    - Nguyen Nguyen: nnguye24@nd.edu

This is a testbench that can be used with xrun for behavioral simulations of the fan speed controller (CSE30342_FinalProject.v)
xrun 
*/

module fan_speed_controller_testbench;

    // Testbench Signals
    reg clk;
    reg reset;
    reg [6:0] temperature_reading;
    reg [6:0] temperature_setpoint;
    reg manual_override;
    reg override_speed;
    wire speed_set;
    wire [2:0] current_state;
    wire [1:0] current_fan_speed;

    // Instantiate the fan speed controller top module
    fan_speed_controller DUT (
        .clk(clk),
        .reset(reset),
        .temperature_reading(temperature_reading),
        .temperature_setpoint(temperature_setpoint),
        .manual_override(manual_override),
        .override_speed(override_speed),
        .speed_set(speed_set),
        .current_fan_speed(current_fan_speed),
        .current_state(current_state)
    );

    // Clock generation
    always begin
        #5 clk = ~clk; // Toggle clock every 5 time units
    end


    // Initialize signals
    initial begin
        // Initial values
        clk = 0;
        reset = 0;
        temperature_reading = 7'd70; // Initial temperature of 70°F
        temperature_setpoint = 7'd70; // Initial setpoint of 70°F
        manual_override = 0;
        override_speed = 0;

        #10;

        // Apply reset
        reset = 1;
        #10 reset = 0;

        #10;
        $display("CSE 30342 Fan Speed Controller Simulation Started");
        // Test sequence: Change temperature and observe fan speed behavior
        $display("Test No.\tTime\tTemp Reading\tTemp Setpoint\tFan Speed");

        // Test 1: Temperature below setpoint (expect fan off)
        temperature_reading = 7'd65; // Test temperature below setpoint
        reset = 1;
        #10 reset = 0;
        #20;
        $display("1\t\t%0t\t%0d\t\t%0d\t\t%0d", $time, temperature_reading, temperature_setpoint, current_fan_speed);

        // Test 2: Temperature equal to setpoint (expect fan off)
        temperature_reading = 7'd70; // Test temperature equal to setpoint
        reset = 1;
        #10 reset = 0;
        #20;
        $display("2\t\t%0t\t%0d\t\t%0d\t\t%0d", $time, temperature_reading, temperature_setpoint, current_fan_speed);

        // Test 3: Temperature between setpoint and low threshold (expect fan low)
        temperature_reading = 7'd74; // Test temperature between setpoint and low threshold
        reset = 1;
        #10 reset = 0;
        #20;
        $display("3\t\t%0t\t%0d\t\t%0d\t\t%0d", $time, temperature_reading, temperature_setpoint, current_fan_speed);

        // Test 4: Temperature between setpoint and medium threshold (expect fan medium)
        temperature_reading = 7'd79; // Test temperature between setpoint and medium threshold
        reset = 1;
        #10 reset = 0;
        #20;
        $display("4\t\t%0t\t%0d\t\t%0d\t\t%0d", $time, temperature_reading, temperature_setpoint, current_fan_speed);

        // Test 5: Temperature above high threshold (expect fan high)
        temperature_reading = 7'd80; // Test temperature above high threshold
        reset = 1;
        #10 reset = 0;
        #20;
        $display("5\t\t%0t\t%0d\t\t%0d\t\t%0d", $time, temperature_reading, temperature_setpoint, current_fan_speed);

        // Test 6: Manual override (turn off fan)
        manual_override = 1;
        override_speed = 0; // Override off
        reset = 1;
        #10 reset = 0;
        #20;
        $display("Manual override with fan off:");
        $display("6\t\t%0t\t%0d\t\t%0d\t\t%0d", $time, temperature_reading, temperature_setpoint, current_fan_speed);

        // Test 7: Manual override (max speed)
        manual_override = 1;
        override_speed = 1; // Override on
        reset = 1;
        #10 reset = 0;
        #20;
        $display("Manual override with fan on:");
        $display("7\t\t%0t\t%0d\t\t%0d\t\t%0d", $time, temperature_reading, temperature_setpoint, current_fan_speed);

        // Test 8: Manual override off (back to temp control)
        temperature_reading = 7'd70; // Test temperature above high threshold
        manual_override = 0;
        override_speed = 1;
        reset = 1;
        #10 reset = 0;
        #20;
        $display("\nReturn to Initial Conditions:");
        $display("1\t\t%0t\t%0d\t\t%0d\t\t%0d", $time, temperature_reading, temperature_setpoint, current_fan_speed);

        //Final Reset
        temperature_reading = 7'd70; // Test temperature above high threshold
        manual_override = 0;
        override_speed = 0;
        reset = 1;
        #10 reset = 0;

        #20;

        // Finish simulation
        $display("CSE 30342 Fan Speed Controller Simulation Complete!");
        $finish;
    end

endmodule



