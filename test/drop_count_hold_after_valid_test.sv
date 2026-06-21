`timescale 1ns/1ps
// ============================================================
// Drop Count Hold After Valid Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   1. Send one invalid packet and confirm drop_cnt = 1.
//   2. Send one valid LOCAL packet without reset.
//   3. Confirm the valid packet is forwarded and drop_cnt stays 1.
//
// Expected:
//   invalid packet: no output, drop_cnt = 1
//   valid packet  : local output is forwarded, drop_cnt remains 1
//
// Spec reason:
//   drop_cnt should increment only for dropped packets.
// ============================================================

`ifndef DROP_COUNT_HOLD_AFTER_VALID_TEST_SV
`define DROP_COUNT_HOLD_AFTER_VALID_TEST_SV

class drop_count_hold_after_valid_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "drop_count_hold_after_valid_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run drop counter hold-after-valid scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr_invalid;
    bird_transaction tr_valid;

    byte unsigned payload_q[$];
    byte unsigned expected_local_q[$];
    byte unsigned actual_local_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" DROP COUNTER HOLD TEST");
      $display(" A valid packet after one drop should not increment drop_cnt.");
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Packet 1: invalid reserved-bit packet
      // --------------------------------------------------------
      tr_invalid = new("drop_count_hold_invalid_transaction");

      payload_q.delete();
      payload_q.push_back(8'hA5);

      tr_invalid.set_valid_local(payload_q, 16'h1357, 5'd1);
      tr_invalid.add_cfg_error_mask(32'h0000_0002);

      tr_invalid.print();
      cov.sample_transaction(tr_invalid);

      send_transaction(tr_invalid);

      local_mon.count_local_activity(10, local_activity_count);
      remote_mon.count_remote_activity(10, remote_activity_count);

      sb.check_next_no_local_activity();
      sb.check_next_no_remote_activity();
      sb.check_drop_count(vif.drop_cnt, 16'd1);
      cov.sample_drop_seen(vif.drop_cnt);

      // --------------------------------------------------------
      // Packet 2: valid local packet
      // --------------------------------------------------------
      tr_valid = new("drop_count_hold_valid_transaction");

      payload_q.delete();
      payload_q.push_back(8'hC3);

      tr_valid.set_valid_local(payload_q, 16'h4567, 5'd1);

      tr_valid.print();
      cov.sample_transaction(tr_valid);

      send_transaction(tr_valid);

      build_expected_local_output(tr_valid, expected_local_q);
      local_mon.capture_bytes(expected_local_q.size(), actual_local_q);

      sb.check_next_local_bytes("drop_count_hold_valid_output", expected_local_q);

      // Valid packet should not increment the existing drop count.
      sb.check_drop_count(vif.drop_cnt, 16'd1);

      // Valid local packet should not activate remote output.
      sb.check_no_remote_output(vif.remote_vld);

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
