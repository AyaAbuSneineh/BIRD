`timescale 1ns/1ps
// ============================================================
// Local Payload Length Large Valid Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send one valid LOCAL packet with PAYLOAD_LEN > 4.
//
// Input packet:
//   traffic_type = LOCAL
//   payload      = 10 20 30 40 50
//   CRC          = CA FE
//   FRAG_NUM     = 1
//   SEQ_NUM      = 1
//
// Expected:
//   local output = 10 20 30 40 50 CA FE
//   no remote output
//   drop_cnt = 0
//
// Spec reason:
//   PAYLOAD_LEN is an 8-bit field. PAYLOAD_LEN = 0 is invalid, but
//   nonzero payload lengths are valid unless another cfg rule is broken.
// ============================================================

`ifndef LOCAL_PAYLOAD_LEN_LARGE_VALID_TEST_SV
`define LOCAL_PAYLOAD_LEN_LARGE_VALID_TEST_SV

class local_payload_len_large_valid_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "local_payload_len_large_valid_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run large local payload scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];
    byte unsigned expected_local_q[$];
    byte unsigned actual_local_q[$];

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" PAYLOAD LENGTH BOUNDARY TEST");
      $display(" This LOCAL packet has PAYLOAD_LEN=5 and should be accepted.");
      $display(" If it is truncated, dropped, or counted as a drop, report a possible DUT bug.");
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create a valid local transaction with PAYLOAD_LEN > 4
      // --------------------------------------------------------
      tr = new("local_payload_len_large_valid_transaction");

      payload_q.delete();
      payload_q.push_back(8'h10);
      payload_q.push_back(8'h20);
      payload_q.push_back(8'h30);
      payload_q.push_back(8'h40);
      payload_q.push_back(8'h50);

      tr.set_valid_local(payload_q, 16'hCAFE, 5'd1);

      tr.print();
      cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction_with_crc_boundary_check(
        tr,
        "local_payload_len_large_valid_payload_crc_boundary"
      );

      // --------------------------------------------------------
      // Build and capture expected local output.
      // --------------------------------------------------------
      build_expected_local_output(tr, expected_local_q);
      local_mon.capture_bytes(expected_local_q.size(), actual_local_q);

      // --------------------------------------------------------
      // Compare using scoreboard
      // --------------------------------------------------------
      sb.check_next_local_bytes("local_payload_len_large_valid_output", expected_local_q);

      // Spec-valid packet, so drop_cnt should stay 0.
      sb.check_drop_count(vif.drop_cnt, 16'd0);

      // Local packet should not activate remote output.
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
