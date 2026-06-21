`timescale 1ns/1ps
// ============================================================
// Remote Payload Length Large Valid Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send one valid REMOTE single-fragment packet with PAYLOAD_LEN > 4.
//
// Input packet:
//   traffic_type = REMOTE
//   payload      = 10 20 30 40 50
//   input CRC    = CA FE
//   FRAG_NUM     = 1
//   SEQ_NUM      = 1
//
// Expected:
//   remote output = packed payload words + regenerated CRC16 word
//   no local output
//   drop_cnt = 0
//
// Spec reason:
//   PAYLOAD_LEN is an 8-bit field. PAYLOAD_LEN = 0 is invalid, but
//   nonzero payload lengths are valid unless another cfg rule is broken.
//   Remote traffic must forward the merged payload and regenerated CRC.
// ============================================================

`ifndef REMOTE_PAYLOAD_LEN_LARGE_VALID_TEST_SV
`define REMOTE_PAYLOAD_LEN_LARGE_VALID_TEST_SV

class remote_payload_len_large_valid_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "remote_payload_len_large_valid_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run large remote payload scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];
    byte unsigned merged_payload_q[$];

    logic [31:0] expected_remote_q[$];
    logic [31:0] actual_remote_q[$];

    int local_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" REMOTE PAYLOAD LENGTH BOUNDARY TEST");
      $display(" This REMOTE packet has PAYLOAD_LEN=5 and should be accepted.");
      $display(" If it is truncated, dropped, or counted as a drop, report a possible DUT bug.");
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create one valid remote transaction with PAYLOAD_LEN > 4
      // --------------------------------------------------------
      tr = new("remote_payload_len_large_valid_transaction");

      payload_q.delete();
      payload_q.push_back(8'h10);
      payload_q.push_back(8'h20);
      payload_q.push_back(8'h30);
      payload_q.push_back(8'h40);
      payload_q.push_back(8'h50);

      tr.set_remote_fragment(
        payload_q,
        5'd1,     // single-fragment remote packet
        5'd1,     // valid sequence number
        16'hCAFE  // input CRC, consumed but not forwarded directly
      );

      tr.print();
      cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction_with_crc_boundary_check(
        tr,
        "remote_payload_len_large_valid_payload_crc_boundary"
      );

      // --------------------------------------------------------
      // Build expected remote output.
      // --------------------------------------------------------
      // Since this is one remote fragment, merged payload = payload_q.
      // For PAYLOAD_LEN=5, expected payload packing is:
      //   word 0 = 40 30 20 10 as 32'h40302010
      //   word 1 = 00 00 00 50 as 32'h00000050
      // followed by the regenerated CRC16 word.
      // --------------------------------------------------------
      merged_payload_q.delete();
      foreach (payload_q[i]) begin
        merged_payload_q.push_back(payload_q[i]);
      end

      build_expected_remote_output(merged_payload_q, expected_remote_q);

      $display("[%0t] %s: expected remote words:", $time, name);
      foreach (expected_remote_q[i]) begin
        $display("  expected_remote_q[%0d] = %08h", i, expected_remote_q[i]);
      end

      // --------------------------------------------------------
      // Capture and compare actual remote output.
      // --------------------------------------------------------
      remote_mon.capture_words(expected_remote_q.size(), actual_remote_q);
      sb.check_next_remote_words("remote_payload_len_large_valid_output", expected_remote_q);

      // Remote traffic should not produce local output.
      local_mon.count_local_activity(10, local_activity_count);
      sb.check_next_no_local_activity();

      // Spec-valid packet, so drop_cnt should stay 0.
      sb.check_drop_count(vif.drop_cnt, 16'd0);

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
