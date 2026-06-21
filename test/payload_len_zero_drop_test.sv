`timescale 1ns/1ps
// ============================================================
// Payload Length Zero Drop Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send a packet with PAYLOAD_LEN = 0 in cfg.
//
// Important:
//   We still send one dummy payload byte plus two CRC bytes,
//   because the DUT samples cfg on the first accepted byte.
//
// Input packet:
//   traffic_type = LOCAL
//   cfg payload_len = 0   // invalid
//   FRAG_NUM = 1
//   SEQ_NUM  = 1
//
// Expected:
//   no local output
//   no remote output
//   drop_cnt = 1
// ============================================================

`ifndef PAYLOAD_LEN_ZERO_DROP_TEST_SV
`define PAYLOAD_LEN_ZERO_DROP_TEST_SV

class payload_len_zero_drop_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "payload_len_zero_drop_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run payload length zero scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];
    int local_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create a local transaction first
      // --------------------------------------------------------
      tr = new("payload_len_zero_transaction");

      payload_q.delete();

      // We send one dummy byte.
      // But later we override cfg payload_len to 0.
      payload_q.push_back(8'hAA);

      // Start from a normally valid local packet.
      tr.set_valid_local(payload_q, 16'h1234);

      // Now make the cfg invalid:
      // PAYLOAD_LEN = 0 is not allowed.
      tr.override_payload_len(8'd0);

      tr.print();
	  cov.sample_transaction(tr);

      send_transaction(tr);

      local_mon.count_local_activity(10, local_activity_count);

      // --------------------------------------------------------
      // Compare using scoreboard
      // --------------------------------------------------------
      sb.check_next_no_local_activity();

      // Invalid packet, so drop_cnt should be 1.
      sb.check_drop_count(vif.drop_cnt, 16'd1);
	    cov.sample_drop_seen(vif.drop_cnt);

      // Invalid packet should not activate remote output.
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