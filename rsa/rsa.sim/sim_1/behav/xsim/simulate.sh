#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2019.1.2 (64-bit)
#
# Filename    : simulate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for simulating the design by launching the simulator
#
# Generated by Vivado on Wed Oct 30 16:01:47 CET 2019
# SW Build 2615518 on Fri Aug  9 15:53:29 MDT 2019
#
# Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
#
# usage: simulate.sh
#
# ****************************************************************************
set -Eeuo pipefail
echo "xsim tb_blakley_behav -key {Behavioral:sim_1:Functional:tb_blakley} -tclbatch tb_blakley.tcl -view /home/crfosse/dds1/TFE4141-DDS1/rsa/tb_blakley_behav.wcfg -log simulate.log"
xsim tb_blakley_behav -key {Behavioral:sim_1:Functional:tb_blakley} -tclbatch tb_blakley.tcl -view /home/crfosse/dds1/TFE4141-DDS1/rsa/tb_blakley_behav.wcfg -log simulate.log

