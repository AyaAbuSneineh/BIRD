`timescale 1ns/1ps
// ============================================================
// Drop Count Accumulation Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send two invalid packets without reset between them.
//
// Packet 1:
//   valid LOCAL fields, but cfg[1] is set.
//
// Packet 2:
//   LOCAL packet with FRAG_NUM = 0.
//
// Expected:
//   after packet 1: no output, drop_cnt = 1
//   after packet 2: no output, drop_cnt = 2
//
// Spec reason:
//   drop_cnt counts dropped packets and should accumulate until reset.
// ============================================================

`ifndef DROP_COUNT_ACCUMULATION_TEST_SV
`define DROP_COUNT_ACCUMULATION_TEST_SV

class drop_count_accumulation_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "drop_count_accumulation_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run drop counter accumulation scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr_reserved;
    bird_transaction tr_frag_zero;

    byte unsigned payload_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" DROP COUNTER ACCUMULATION TEST");
      $display(" Two invalid packets should increment drop_cnt from 0 to 1 to 2.");
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Packet 1: reserved bit violation
      // --------------------------------------------------------
      tr_reserved = new("drop_count_reserved_bit_transaction");

      payload_q.delete();
      payload_q.push_back(8'hA1);

      tr_reserved.set_valid_local(payload_q, 16'h1111, 5'd1);
      tr_reserved.add_cfg_error_mask(32'h0000_0002);

      tr_reserved.print();
      cov.sample_transaction(tr_reserved);

      send_transaction(tr_reserved);

      local_mon.count_local_activity(10, local_activity_count);
      remote_mon.count_remote_activity(10, remote_activity_count);

      sb.check_next_no_local_activity();
      sb.check_next_no_remote_activity();
      sb.check_drop_count(vif.drop_cnt, 16'd1);
      cov.sample_drop_seen(vif.drop_cnt);

      // --------------------------------------------------------
      // Packet 2: local FRAG_NUM = 0 violation
      // --------------------------------------------------------
      tr_frag_zero = new("drop_count_frag_zero_transaction");

      payload_q.delete();
      payload_q.push_back(8'hB2);

      tr_frag_zero.set_local_custom(
        payload_q,
        5'd0,     // invalid local frag_num
        5'd1,     // valid seq_num
        16'h2222  // input CRC
      );

      tr_frag_zero.print();
      cov.sample_transaction(tr_frag_zero);

      send_transaction(tr_frag_zero);

      local_mon.count_local_activity(10, local_activity_count);
      remote_mon.count_remote_activity(10, remote_activity_count);

      sb.check_next_no_local_activity();
      sb.check_next_no_remote_activity();
      sb.check_drop_count(vif.drop_cnt, 16'd2);
      cov.sample_drop_seen(vif.drop_cnt);

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
