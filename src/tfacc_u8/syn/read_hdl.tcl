
add_files ../bd/design_1/design_1.bd

read_verilog -library xil_defaultlib -sv {
  ../hdl/acc/logic_types.svh
  ../hdl/acc/u8adrgen.sv
  ../hdl/acc/u8mac.sv
  ../hdl/acc/rd_cache_nk.sv
  ../hdl/acc/tfacc_core.sv
  ../hdl/acc/input_cache.sv
  ../hdl/acc/input_arb.sv
  ../hdl/acc/output_cache.sv
  ../hdl/acc/output_arb.sv
  ../hdl/tfacc_memif.sv
}
read_verilog -library xil_defaultlib {
  ../hdl/tfacc_cpu_v1_0.v
  ../bd/design_1/hdl/design_1_wrapper.v
}
read_vhdl -library xil_defaultlib {
  ../hdl/sr_core/pkg_optab-fp.vhd
  ../hdl/sr_core/pkg_sr_core.vhd
  ../hdl/sr_core/pkg_sr_dbg.vhd
  ../hdl/sr_core/pkg_sr_pu.vhd
  ../hdl/sr_core/sr_alu.vhd
  ../hdl/sr_core/sr_core.vhd
  ../hdl/sr_core/sr_dmac.vhd
  ../hdl/sr_core/sr_fpu.vhd
  ../hdl/sr_core/sr_mem.vhd
  ../hdl/sr_core/sr_pu.vhd
  ../hdl/sr_core/sr_regs.vhd
  ../hdl/sr_core/sr_sio.vhd
  ../hdl/sr_core/sr_timer.vhd
}

set_property file_type "Verilog Header" [get_files ../hdl/acc/logic_types.svh]
#set_property is_global_include true [get_files ../hdl/acc/logic_types.svh]


