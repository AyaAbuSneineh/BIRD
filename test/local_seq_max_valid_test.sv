`timescale 1ns/1ps
// ============================================================
// Local SEQ_NUM Max Valid Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send a LOCAL packet with SEQ_NUM = 31.
//
// Input packet:
//   traffic_type = LOCAL
//   payload      = 5A
//   CRC          = AB CD
//   FRAG_NUM     = 1
//   SEQ_NUM      = 31
//
// Expected:
//   local output = 5A AB CD
//   no remote output
//   drop_cnt = 0
//
// Spec reason:
//   Valid SEQ_NUM values are 1..31. For local traffic, SEQ_NUM
//   identifies the packet but has no functional impact on routing.
// ============================================================

`ifndef LOCAL_SEQ_MAX_VALID_TEST_SV
`define LOCAL_SEQ_MAX_VALID_TEST_SV

class local_seq_max_valid_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "local_seq_max_valid_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run local SEQ_NUM = 31 valid boundary scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];
    byte unsigned expected_local_q[$];
    byte unsigned actual_local_q[$];

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" SPEC-BASED BOUNDARY TEST");
      $display(" This packet is valid by the PDF spec: LOCAL, FRAG_NUM=1, SEQ_NUM=31.");
      $display(" If the DUT drops it or increments drop_cnt, report a possible DUT bug.");
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create a spec-valid local transaction
      // --------------------------------------------------------
      tr = new("local_seq_max_valid_transaction");

      payload_q.delete();
      payload_q.push_back(8'h5A);

      // Upper valid SEQ_NUM boundary for local traffic.
      tr.set_local_custom(
        payload_q,
        5'd1,     // valid local frag_num
        5'd31,    // max valid seq_num
        16'hABCD  // input CRC
      );

      tr.print();
      cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction(tr);

      // --------------------------------------------------------
      // Build and capture expected local output.
      // --------------------------------------------------------
      build_expected_local_output(tr, expected_local_q);
      local_mon.capture_bytes(expected_local_q.size(), actual_local_q);

      // --------------------------------------------------------
      // Compare using scoreboard
      // --------------------------------------------------------
      sb.check_next_local_bytes("local_seq_max_valid_output", expected_local_q);

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
