`timescale 1ns/1ps
// ============================================================
// Reset Initial Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Keep rst_n = 0 for a few clock cycles.
//
// Expected:
//   local_vld   = 0
//   remote_vld  = 0
//   drop_cnt    = 0
// ============================================================

`ifndef RESET_INITIAL_TEST_SV
`define RESET_INITIAL_TEST_SV

class reset_initial_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(
    virtual bird_if vif,
    string name = "reset_initial_test"
  );
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run reset initial scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display("========================================");	 
	  
	  cov.sample_reset_initial();

      // Initialize all testbench-driven signals.
      // init_signals keeps rst_n = 0.
      vif.init_signals();

      // Keep outputs not ready during reset.
      vif.local_rdy  = 1'b0;
      vif.remote_rdy = 1'b0;

      $display("[%0t] %s: reset is active", $time, name);

      // Hold reset active for a few clock cycles.
      repeat (3) @(posedge vif.clk);

      // Check reset behavior while reset is still active.
      sb.check_reset_outputs(
        vif.local_vld,
        vif.data_local,
        vif.remote_vld,
        vif.data_remote,
        vif.drop_cnt
      );

      // Release reset after checking.
      @(negedge vif.clk);
      vif.rst_n = 1'b1;

      $display("[%0t] %s: reset released", $time, name);

      repeat (5) @(posedge vif.clk);

      // Print final report.
	  final_report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif
