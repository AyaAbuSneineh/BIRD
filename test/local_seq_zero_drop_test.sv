`timescale 1ns/1ps
// ============================================================
// Local SEQ_NUM Zero Drop Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send a LOCAL packet with SEQ_NUM = 0.
//
// Input packet:
//   traffic_type = LOCAL
//   payload      = AA
//   CRC          = 12 34
//   FRAG_NUM     = 1
//   SEQ_NUM      = 0   // invalid
//
// Expected:
//   no local output
//   no remote output
//   drop_cnt = 1
//
// Spec reason:
//   The cfg table defines SEQ_NUM value 0 as invalid. Valid packet
//   sequence numbers are 1..31.
// ============================================================

`ifndef LOCAL_SEQ_ZERO_DROP_TEST_SV
`define LOCAL_SEQ_ZERO_DROP_TEST_SV

class local_seq_zero_drop_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "local_seq_zero_drop_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run local SEQ_NUM = 0 invalid scenario
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
      tr = new("local_seq_zero_drop_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // LOCAL traffic with FRAG_NUM = 1 but SEQ_NUM = 0.
      // SEQ_NUM = 0 is invalid by the PDF cfg table, so this
      // packet must be dropped.
      tr.set_local_custom(
        payload_q,
        5'd1,     // valid local frag_num
        5'd0,     // invalid seq_num
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
