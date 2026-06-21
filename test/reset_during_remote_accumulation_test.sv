`timescale 1ns/1ps
// ============================================================
// Reset During Remote Accumulation Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   1. Start accumulating an incomplete REMOTE packet.
//   2. Assert reset before the missing fragment arrives.
//   3. Verify reset clears outputs and drop_cnt.
//   4. Send a valid LOCAL packet after reset to prove the DUT can
//      resume from a clean state.
//
// Expected:
//   no remote output before reset
//   reset clears local_vld, remote_vld, and drop_cnt
//   valid local packet after reset forwards normally
//
// Spec reason:
//   Reset must clear the design state. Remote accumulation is internal
//   state and must not survive reset.
// ============================================================

`ifndef RESET_DURING_REMOTE_ACCUMULATION_TEST_SV
`define RESET_DURING_REMOTE_ACCUMULATION_TEST_SV

class reset_during_remote_accumulation_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "reset_during_remote_accumulation_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run reset during remote accumulation scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction remote_frag2_tr;
    bird_transaction local_tr;

    byte unsigned payload_q[$];
    byte unsigned expected_local_q[$];
    byte unsigned actual_local_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" RESET DURING REMOTE ACCUMULATION TEST");
      $display(" Reset must clear an incomplete remote packet and allow clean traffic after reset.");
      $display("========================================");

      // Start from clean reset.
      apply_reset();

      // --------------------------------------------------------
      // Start an incomplete remote packet.
      // FRAG_NUM=2 means fragment 1 is still missing.
      // --------------------------------------------------------
      remote_frag2_tr = new("reset_during_remote_accumulation_frag2_transaction");

      payload_q.delete();
      payload_q.push_back(8'h22);

      remote_frag2_tr.set_remote_fragment(
        payload_q,
        5'd2,     // fragment position 2
        5'd1,     // packet sequence number
        16'h2222  // input CRC, consumed but not forwarded directly
      );

      remote_frag2_tr.print();
      cov.sample_transaction(remote_frag2_tr);

      send_transaction(remote_frag2_tr);

      // Incomplete packet should not produce remote output.
      remote_mon.count_remote_activity(5, remote_activity_count);
      sb.check_next_no_remote_activity();

      // --------------------------------------------------------
      // Assert reset while remote accumulation state is active.
      // --------------------------------------------------------
      $display("[%0t] %s: asserting reset during remote accumulation", $time, name);

      @(negedge vif.clk);
      vif.rst_n      = 1'b0;
      vif.in_vld     = 1'b0;
      vif.data_in    = 8'h00;
      vif.cfg        = 32'h0000_0000;
      vif.local_rdy  = 1'b0;
      vif.remote_rdy = 1'b0;

      repeat (3) @(posedge vif.clk);

      sb.check_reset_outputs(
        vif.local_vld,
        vif.data_local,
        vif.remote_vld,
        vif.data_remote,
        vif.drop_cnt
      );

      @(negedge vif.clk);
      vif.rst_n = 1'b1;

      $display("[%0t] %s: reset released after remote accumulation", $time, name);

      repeat (2) @(posedge vif.clk);
      sb.check_drop_count(vif.drop_cnt, 16'd0);

      // --------------------------------------------------------
      // Send a valid local packet after reset.
      // --------------------------------------------------------
      local_tr = new("reset_during_remote_accumulation_post_reset_local_transaction");

      payload_q.delete();
      payload_q.push_back(8'hA5);

      local_tr.set_valid_local(payload_q, 16'h1234, 5'd1);

      local_tr.print();
      cov.sample_transaction(local_tr);

      send_transaction(local_tr);

      build_expected_local_output(local_tr, expected_local_q);
      fork
        local_mon.capture_bytes(expected_local_q.size(), actual_local_q);
        remote_mon.count_remote_activity(20, remote_activity_count);
      join

      sb.check_next_local_bytes("reset_during_remote_accumulation_post_reset_local_output", expected_local_q);
      sb.check_next_no_remote_activity();
      sb.check_drop_count(vif.drop_cnt, 16'd0);

      repeat (5) @(posedge vif.clk);

      cov.sample_reset_during_remote_accumulation();
      final_report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif
