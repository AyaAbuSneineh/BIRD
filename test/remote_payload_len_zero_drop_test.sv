`timescale 1ns/1ps
// ============================================================
// Remote Payload Length Zero Drop Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send a REMOTE packet with PAYLOAD_LEN = 0 in cfg.
//
// Important:
//   We still send one dummy payload byte plus two CRC bytes,
//   because the DUT samples cfg on the first accepted byte.
//
// Input packet:
//   traffic_type    = REMOTE
//   cfg payload_len = 0   // invalid
//   FRAG_NUM        = 1
//   SEQ_NUM         = 1
//
// Expected:
//   no local output
//   no remote output
//   drop_cnt = 1
//
// Spec reason:
//   PAYLOAD_LEN must be nonzero for both local and remote traffic.
// ============================================================

`ifndef REMOTE_PAYLOAD_LEN_ZERO_DROP_TEST_SV
`define REMOTE_PAYLOAD_LEN_ZERO_DROP_TEST_SV

class remote_payload_len_zero_drop_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "remote_payload_len_zero_drop_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run remote payload length zero scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" REMOTE PAYLOAD_LEN ZERO DROP TEST");
      $display(" PAYLOAD_LEN=0 is invalid and should be dropped.");
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create a remote transaction first
      // --------------------------------------------------------
      tr = new("remote_payload_len_zero_transaction");

      payload_q.delete();

      // We send one dummy byte.
      // But later we override cfg payload_len to 0.
      payload_q.push_back(8'hAA);

      // Start from a normally valid remote packet.
      tr.set_remote_fragment(
        payload_q,
        5'd1,     // valid frag_num
        5'd1,     // valid seq_num
        16'h1234  // input CRC
      );

      // Now make the cfg invalid:
      // PAYLOAD_LEN = 0 is not allowed.
      tr.override_payload_len(8'd0);

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
