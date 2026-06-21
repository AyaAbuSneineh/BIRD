`timescale 1ns/1ps
// ============================================================
// Remote SEQ_NUM Zero Drop Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send a REMOTE packet with SEQ_NUM = 0.
//
// Input packet:
//   traffic_type = REMOTE
//   payload      = AA
//   input CRC    = 12 34
//   FRAG_NUM     = 1
//   SEQ_NUM      = 0   // invalid for remote traffic
//
// Expected:
//   no local output
//   no remote output
//   drop_cnt = 1
// ============================================================

`ifndef REMOTE_SEQ_ZERO_DROP_TEST_SV
`define REMOTE_SEQ_ZERO_DROP_TEST_SV

class remote_seq_zero_drop_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "remote_seq_zero_drop_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run remote SEQ_NUM zero scenario
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
      // Create an invalid remote transaction
      // --------------------------------------------------------
      tr = new("remote_seq_zero_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // Remote traffic with SEQ_NUM = 0.
      // This is invalid, so the DUT should drop the packet.
      tr.set_remote_fragment(
        payload_q,
        5'd1,     // frag_num
        5'd0,     // invalid seq_num for remote traffic
        16'h1234  // input CRC
      );

      tr.print();
	  cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction(tr);

      // --------------------------------------------------------
      // Since packet is invalid, no output should appear.
      // --------------------------------------------------------
      local_mon.count_local_activity(10, local_activity_count);
      remote_mon.count_remote_activity(10, remote_activity_count);

      // --------------------------------------------------------
      // Compare using scoreboard
      // --------------------------------------------------------
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