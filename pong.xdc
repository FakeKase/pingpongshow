# ===================== Basys3 Pong Constraints =====================
# - VGA: RED[3:0], GREEN[3:0], BLUE[3:0], HS, VS
# - CLK: 100 MHz
# - RESET: btn_reset (on-board) active-high
# - LEDs: ledL[3:0], ledR[3:0]
# - Player 2 Buttons: PMOD JA1-JA4 (active-low + PULLUP)
# - Player 1 Buttons: PMOD JB1-JB4 (active-low + PULLUP)
# ===================================================================

# ===================== VGA PIN ASSIGNMENTS =======================

# RED
set_property IOSTANDARD LVCMOS33 [get_ports {RED[*]}]
set_property PACKAGE_PIN G19 [get_ports {RED[0]}]
set_property PACKAGE_PIN H19 [get_ports {RED[1]}]
set_property PACKAGE_PIN J19 [get_ports {RED[2]}]
set_property PACKAGE_PIN N19 [get_ports {RED[3]}]

# GREEN
set_property IOSTANDARD LVCMOS33 [get_ports {GREEN[*]}]
set_property PACKAGE_PIN J17 [get_ports {GREEN[0]}]
set_property PACKAGE_PIN H17 [get_ports {GREEN[1]}]
set_property PACKAGE_PIN G17 [get_ports {GREEN[2]}]
set_property PACKAGE_PIN D17 [get_ports {GREEN[3]}]

# BLUE
set_property IOSTANDARD LVCMOS33 [get_ports {BLUE[*]}]
set_property PACKAGE_PIN N18 [get_ports {BLUE[0]}]
set_property PACKAGE_PIN L18 [get_ports {BLUE[1]}]
set_property PACKAGE_PIN K18 [get_ports {BLUE[2]}]
set_property PACKAGE_PIN J18 [get_ports {BLUE[3]}]

# SYNC
set_property PACKAGE_PIN P19 [get_ports HS]
set_property IOSTANDARD LVCMOS33 [get_ports HS]

set_property PACKAGE_PIN R19 [get_ports VS]
set_property IOSTANDARD LVCMOS33 [get_ports VS]

# ===================== CLOCK =====================

set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]

# ===================== RESET (on-board) =====================

set_property PACKAGE_PIN U17 [get_ports btn_reset]
set_property IOSTANDARD LVCMOS33 [get_ports btn_reset]

# ===================== LEDs =====================

set_property IOSTANDARD LVCMOS33 [get_ports {ledL[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ledR[*]}]

set_property PACKAGE_PIN L1 [get_ports {ledL[3]}]
set_property PACKAGE_PIN P1 [get_ports {ledL[2]}]
set_property PACKAGE_PIN N3 [get_ports {ledL[1]}]
set_property PACKAGE_PIN P3 [get_ports {ledL[0]}]

set_property PACKAGE_PIN V19 [get_ports {ledR[3]}]
set_property PACKAGE_PIN U19 [get_ports {ledR[2]}]
set_property PACKAGE_PIN E19 [get_ports {ledR[1]}]
set_property PACKAGE_PIN U16 [get_ports {ledR[0]}]

# ================= Player 2 Buttons (PMOD JA1-JA4) =================
# active-low with internal pull-up (press = 0)

set_property IOSTANDARD LVCMOS33 [get_ports btn2_up]
set_property PACKAGE_PIN J1 [get_ports btn2_up]
set_property PULLUP true [get_ports btn2_up]

set_property IOSTANDARD LVCMOS33 [get_ports btn2_dn]
set_property PACKAGE_PIN L2 [get_ports btn2_dn]
set_property PULLUP true [get_ports btn2_dn]

set_property IOSTANDARD LVCMOS33 [get_ports btn2_left]
set_property PACKAGE_PIN J2 [get_ports btn2_left]
set_property PULLUP true [get_ports btn2_left]

set_property IOSTANDARD LVCMOS33 [get_ports btn2_right]
set_property PACKAGE_PIN G2 [get_ports btn2_right]
set_property PULLUP true [get_ports btn2_right]

# ================= Player 1 Buttons (PMOD JB1-JB4) =================
# active-low with internal pull-up (press = 0)

set_property IOSTANDARD LVCMOS33 [get_ports btn1_up]
set_property PACKAGE_PIN A14 [get_ports btn1_up]
set_property PULLUP true [get_ports btn1_up]

set_property IOSTANDARD LVCMOS33 [get_ports btn1_dn]
set_property PACKAGE_PIN A16 [get_ports btn1_dn]
set_property PULLUP true [get_ports btn1_dn]

set_property IOSTANDARD LVCMOS33 [get_ports btn1_left]
set_property PACKAGE_PIN B15 [get_ports btn1_left]
set_property PULLUP true [get_ports btn1_left]

set_property IOSTANDARD LVCMOS33 [get_ports btn1_right]
set_property PACKAGE_PIN B16 [get_ports btn1_right]
set_property PULLUP true [get_ports btn1_right]

set_property IOSTANDARD LVCMOS33 [get_ports pause]
set_property PACKAGE_PIN V17 [get_ports pause]
