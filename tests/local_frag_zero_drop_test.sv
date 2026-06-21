`timescale 1ns/1ps
// ============================================================
// Local FRAG_NUM Zero Drop Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send a LOCAL packet with FRAG_NUM = 0.
//
// Input packet:
//   traffic_type = LOCAL
//   payload      = AA
//   CRC          = 12 34
//   FRAG_NUM     = 0   // invalid for local traffic
//   SEQ_NUM      = 1
//
// Expected:
//   no local output
//   no remote output
//   drop_cnt = 1
//
// Spec reason:
//   Local traffic is single-fragment traffic and must use FRAG_NUM = 1.
// ============================================================

`ifndef LOCAL_FRAG_ZERO_DROP_TEST_SV
`define LOCAL_FRAG_ZERO_DROP_TEST_SV

class local_frag_zero_drop_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "local_frag_zero_drop_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run local FRAG_NUM = 0 invalid scenario
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

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create an invalid local transaction
      // --------------------------------------------------------
      tr = new("local_frag_zero_drop_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // LOCAL traffic with FRAG_NUM = 0.
      // Local packets are single-fragment packets and must use
      // FRAG_NUM = 1, so this packet must be dropped.
      tr.set_local_custom(
        payload_q,
        5'd0,     // invalid local frag_num
        5'd1,     // valid seq_num
        16'h1234  // input CRC
      );

      tr.print();
      cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction(tr);

      // --------------------------------------------------------
      // Invalid packet should not produce either output stream.
      // --------------------------------------------------------
      local_mon.count_local_activity(10, local_activity_count);
      remote_mon.count_remote_activity(10, remote_activity_count);

      sb.check_next_no_local_activity();
      sb.check_next_no_remote_activity();

      // Invalid packet, so drop_cnt should be 1.
      sb.check_drop_count(vif.drop_cnt, 16'd1);
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
