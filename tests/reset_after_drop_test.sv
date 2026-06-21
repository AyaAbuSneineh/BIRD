`timescale 1ns/1ps
// ============================================================
// Reset After Drop Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   1. Send a LOCAL packet with an invalid reserved cfg bit.
//   2. Check that drop_cnt becomes 1.
//   3. Assert reset again.
//   4. Check that drop_cnt clears back to 0.
//
// Expected:
//   before reset:
//     drop_cnt = 1
//
//   during reset:
//     local_vld   = 0
//     remote_vld  = 0
//     drop_cnt    = 0
// ============================================================

`ifndef RESET_AFTER_DROP_TEST_SV
`define RESET_AFTER_DROP_TEST_SV

class reset_after_drop_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(
    virtual bird_if vif,
    string name = "reset_after_drop_test"
  );
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run reset after drop scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display("========================================");

      // --------------------------------------------------------
      // First reset: start from clean state
      // --------------------------------------------------------
      apply_reset();

      // --------------------------------------------------------
      // Create an invalid LOCAL packet using a spec-defined
      // drop condition: a reserved cfg bit is non-zero.
      // --------------------------------------------------------
      tr = new("reset_after_drop_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // Start from a valid local packet, then set cfg[1].
      // cfg[1] is reserved by the PDF specification and must be 0.
      tr.set_valid_local(payload_q, 16'h1234, 5'd1);
      tr.add_cfg_error_mask(32'h0000_0002);

      tr.print();
	  cov.sample_transaction(tr);
	  

      // --------------------------------------------------------
      // Send invalid packet
      // --------------------------------------------------------
      send_transaction(tr);

      // --------------------------------------------------------
      // Invalid packet should not produce output
      // --------------------------------------------------------
      local_mon.count_local_activity(10, local_activity_count);
      remote_mon.count_remote_activity(10, remote_activity_count);

      sb.check_next_no_local_activity();
      sb.check_next_no_remote_activity();

      // Before reset, drop_cnt should be 1.
      sb.check_drop_count(vif.drop_cnt, 16'd1);
	  cov.sample_drop_seen(vif.drop_cnt);

      // --------------------------------------------------------
      // Second reset: check that drop_cnt clears
      // --------------------------------------------------------
      $display("[%0t] %s: asserting reset after drop",
               $time, name);

      @(negedge vif.clk);

      vif.rst_n      = 1'b0;
      vif.in_vld     = 1'b0;
      vif.data_in    = 8'h00;
      vif.cfg        = 32'h0000_0000;
      vif.local_rdy  = 1'b0;
      vif.remote_rdy = 1'b0;

      // Hold reset active for a few cycles.
      repeat (3) @(posedge vif.clk);

      // Check reset behavior while reset is active.
      sb.check_reset_outputs(
        vif.local_vld,
        vif.data_local,
        vif.remote_vld,
        vif.data_remote,
        vif.drop_cnt
      );

      // Release reset again.
      @(negedge vif.clk);
      vif.rst_n = 1'b1;

      $display("[%0t] %s: reset released again",
               $time, name);

      repeat (5) @(posedge vif.clk);

      // Print final report.
	  cov.sample_reset_after_drop();
      final_report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif
