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

# CLOCK
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]

# BUTTONS
set_property PACKAGE_PIN T18 [get_ports btn_up]
set_property IOSTANDARD LVCMOS33 [get_ports btn_up]

set_property PACKAGE_PIN U18 [get_ports btn_dn]
set_property IOSTANDARD LVCMOS33 [get_ports btn_dn]

set_property PACKAGE_PIN U17 [get_ports btn_reset]
set_property IOSTANDARD LVCMOS33 [get_ports btn_reset]

set_property IOSTANDARD LVCMOS33 [get_ports btn_left]
set_property PACKAGE_PIN W19 [get_ports btn_left]
set_property PACKAGE_PIN T17 [get_ports btn_right]
set_property IOSTANDARD LVCMOS33 [get_ports btn_right]

### Seven Segment Display
#set_property PACKAGE_PIN W7  [get_ports {seg[0]}] ;# CA
#set_property PACKAGE_PIN W6  [get_ports {seg[1]}] ;# CB
#set_property PACKAGE_PIN U8  [get_ports {seg[2]}] ;# CC
#set_property PACKAGE_PIN V8  [get_ports {seg[3]}] ;# CD
#set_property PACKAGE_PIN U5  [get_ports {seg[4]}] ;# CE
#set_property PACKAGE_PIN V5  [get_ports {seg[5]}] ;# CF
#set_property PACKAGE_PIN U7  [get_ports {seg[6]}] ;# CG

#set_property PACKAGE_PIN V7  [get_ports {dp}]     ;# DP

### Digit Enable (Anodes)
#set_property PACKAGE_PIN U2  [get_ports {an[0]}]  ;# AN0
#set_property PACKAGE_PIN U4  [get_ports {an[1]}]  ;# AN1
#set_property PACKAGE_PIN V4  [get_ports {an[2]}]  ;# AN2
#set_property PACKAGE_PIN W4  [get_ports {an[3]}]  ;# AN3


set_property IOSTANDARD LVCMOS33 [get_ports {ledL[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ledL[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ledL[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ledL[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ledR[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ledR[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ledR[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ledR[0]}]
set_property PACKAGE_PIN L1 [get_ports {ledL[3]}]
set_property PACKAGE_PIN P1 [get_ports {ledL[2]}]
set_property PACKAGE_PIN N3 [get_ports {ledL[1]}]
set_property PACKAGE_PIN P3 [get_ports {ledL[0]}]
set_property PACKAGE_PIN V19 [get_ports {ledR[3]}]
set_property PACKAGE_PIN U19 [get_ports {ledR[2]}]
set_property PACKAGE_PIN E19 [get_ports {ledR[1]}]
set_property PACKAGE_PIN U16 [get_ports {ledR[0]}]
