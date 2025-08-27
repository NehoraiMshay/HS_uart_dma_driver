# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "DEBUG_ON" -parent ${Page_0}
  set FIFO_DEPTH [ipgui::add_param $IPINST -name "FIFO_DEPTH" -parent ${Page_0}]
  set_property tooltip {actual Fifo Depth = Fifo Depth-1} ${FIFO_DEPTH}
  ipgui::add_param $IPINST -name "baudRate" -parent ${Page_0}
  set clk_Mhz [ipgui::add_param $IPINST -name "clk_Mhz" -parent ${Page_0}]
  set_property tooltip {Clock frequeny in Mhz} ${clk_Mhz}
  ipgui::add_param $IPINST -name "dataWidth" -parent ${Page_0}


}

proc update_PARAM_VALUE.DEBUG_ON { PARAM_VALUE.DEBUG_ON } {
	# Procedure called to update DEBUG_ON when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEBUG_ON { PARAM_VALUE.DEBUG_ON } {
	# Procedure called to validate DEBUG_ON
	return true
}

proc update_PARAM_VALUE.FIFO_DEPTH { PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to update FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIFO_DEPTH { PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to validate FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.baudRate { PARAM_VALUE.baudRate } {
	# Procedure called to update baudRate when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.baudRate { PARAM_VALUE.baudRate } {
	# Procedure called to validate baudRate
	return true
}

proc update_PARAM_VALUE.clk_Mhz { PARAM_VALUE.clk_Mhz } {
	# Procedure called to update clk_Mhz when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.clk_Mhz { PARAM_VALUE.clk_Mhz } {
	# Procedure called to validate clk_Mhz
	return true
}

proc update_PARAM_VALUE.dataWidth { PARAM_VALUE.dataWidth } {
	# Procedure called to update dataWidth when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.dataWidth { PARAM_VALUE.dataWidth } {
	# Procedure called to validate dataWidth
	return true
}


proc update_MODELPARAM_VALUE.DEBUG_ON { MODELPARAM_VALUE.DEBUG_ON PARAM_VALUE.DEBUG_ON } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEBUG_ON}] ${MODELPARAM_VALUE.DEBUG_ON}
}

proc update_MODELPARAM_VALUE.baudRate { MODELPARAM_VALUE.baudRate PARAM_VALUE.baudRate } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.baudRate}] ${MODELPARAM_VALUE.baudRate}
}

proc update_MODELPARAM_VALUE.clk_Mhz { MODELPARAM_VALUE.clk_Mhz PARAM_VALUE.clk_Mhz } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.clk_Mhz}] ${MODELPARAM_VALUE.clk_Mhz}
}

proc update_MODELPARAM_VALUE.FIFO_DEPTH { MODELPARAM_VALUE.FIFO_DEPTH PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIFO_DEPTH}] ${MODELPARAM_VALUE.FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.dataWidth { MODELPARAM_VALUE.dataWidth PARAM_VALUE.dataWidth } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.dataWidth}] ${MODELPARAM_VALUE.dataWidth}
}

