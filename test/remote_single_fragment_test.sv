`timescale 1ns/1ps
// ============================================================
// Remote Single Fragment Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send one valid REMOTE fragment.
//
// Input packet:
//   traffic_type = REMOTE
//   payload      = AA
//   input CRC    = 12 34
//   FRAG_NUM     = 1
//   SEQ_NUM      = 1
//
// Expected:
//   remote output word 0 = 000000AA
//   remote output word 1 = {16'h0000, regenerated_crc}
//   no local output
//   drop_cnt = 0
// ============================================================

`ifndef REMOTE_SINGLE_FRAGMENT_TEST_SV
`define REMOTE_SINGLE_FRAGMENT_TEST_SV

class remote_single_fragment_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  
  function new(virtual bird_if vif,string name = "remote_single_fragment_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run remote single fragment scenario
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
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create a valid remote transaction
      // --------------------------------------------------------
      tr = new("remote_single_fragment_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // Remote fragment:
      //   payload      = AA
      //   frag_num     = 1
      //   seq_num      = 1
      //   input CRC    = 16'h1234
      //
      // Note:
      //   For remote output, the spec does not forward this input CRC.
      //   BIRD regenerates a new CRC over the merged payload.
      tr.set_remote_fragment(
        payload_q,
        5'd1,     // frag_num
        5'd1,     // seq_num
        16'h1234  // input CRC, consumed but not forwarded directly
      );

      tr.print();
	  cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction(tr);

      // --------------------------------------------------------
      // Build expected remote output
      // --------------------------------------------------------
      // Since this is one fragment only, merged payload = payload_q.
      // --------------------------------------------------------
      merged_payload_q.delete();
      foreach (payload_q[i]) begin
        merged_payload_q.push_back(payload_q[i]);
      end

      build_expected_remote_output(merged_payload_q, expected_remote_q);

      $display("[%0t] %s: expected remote words:", $time, name);
      foreach (expected_remote_q[i]) begin
        $display("  expected_remote_q[%0d] = %08h",
                 i, expected_remote_q[i]);
      end

      // --------------------------------------------------------
      // Capture actual remote output
      // --------------------------------------------------------
      remote_mon.capture_words(expected_remote_q.size(), actual_remote_q);

      // --------------------------------------------------------
      // Compare remote output using scoreboard
      // --------------------------------------------------------
      sb.check_next_remote_words("remote_single_fragment_output", expected_remote_q);

      // --------------------------------------------------------
      // Since this is remote traffic, no local output should appear.
      // --------------------------------------------------------
      local_mon.count_local_activity(10, local_activity_count);
      sb.check_next_no_local_activity();

      // Valid packet, so drop_cnt should stay 0.
      sb.check_drop_count(vif.drop_cnt, 16'd0);

      repeat (5) @(posedge vif.clk);

      // Print final report.
      cov.sample_remote_single_fragment();
      final_report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif
