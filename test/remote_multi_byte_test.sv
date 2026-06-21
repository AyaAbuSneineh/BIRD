`timescale 1ns/1ps
// ============================================================
// Remote Multi-Byte Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send one valid REMOTE fragment with multiple payload bytes.
//
// Input packet:
//   traffic_type = REMOTE
//   payload      = AA BB CC DD
//   input CRC    = 12 34
//   FRAG_NUM     = 1
//   SEQ_NUM      = 1
//
// Expected remote output:
//   word 0 = DDCCBBAA
//   word 1 = {16'h0000, regenerated_crc}
//
// Why DDCCBBAA?
//   The PDF does not define byte packing on the 32-bit remote output.
//   The provided DUT/demo packs bytes little-endian inside the word:
//     word[7:0]   = AA
//     word[15:8]  = BB
//     word[23:16] = CC
//     word[31:24] = DD
// ============================================================

`ifndef REMOTE_MULTI_BYTE_TEST_SV
`define REMOTE_MULTI_BYTE_TEST_SV

class remote_multi_byte_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "remote_multi_byte_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run remote multi-byte scenario
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
      $display(" SPEC-BASED FINDING TARGET");
      $display(" This packet is valid by the PDF spec: REMOTE payload plus regenerated CRC.");
      $display(" If the DUT drops it, truncates it, or packs it incorrectly, report a possible DUT bug.");
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create one valid remote transaction
      // --------------------------------------------------------
      tr = new("remote_multi_byte_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);
      payload_q.push_back(8'hBB);
      payload_q.push_back(8'hCC);
      payload_q.push_back(8'hDD);

      // Remote fragment:
      //   payload   = AA BB CC DD
      //   frag_num  = 1
      //   seq_num   = 1
      //   input CRC = 16'h1234
      //
      // For remote output, input CRC is consumed but not forwarded.
      // The DUT regenerates CRC over the merged payload.
      tr.set_remote_fragment(
        payload_q,
        5'd1,     // frag_num
        5'd1,     // seq_num
        16'h1234  // input CRC
      );

      tr.print();
	  cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction_with_crc_boundary_check(
        tr,
        "remote_multi_byte_payload_crc_boundary"
      );

      // --------------------------------------------------------
      // Build expected remote output
      // --------------------------------------------------------
      // Since this is one fragment only:
      //   merged_payload = payload_q
      // --------------------------------------------------------
      merged_payload_q.delete();
      foreach (payload_q[i]) begin
        merged_payload_q.push_back(payload_q[i]);
      end

      build_expected_remote_output(merged_payload_q, expected_remote_q);

      $display("[%0t] %s: expected remote words:", $time, name);
      foreach (expected_remote_q[i]) begin
        $display("  expected_remote_q[%0d] = %08h",i, expected_remote_q[i]);
      end

      // --------------------------------------------------------
      // Capture actual remote output
      // --------------------------------------------------------
      remote_mon.capture_words(expected_remote_q.size(), actual_remote_q);

      // --------------------------------------------------------
      // Compare remote output using scoreboard
      // --------------------------------------------------------
      sb.check_next_remote_words("remote_multi_byte_output", expected_remote_q);

      // --------------------------------------------------------
      // Remote traffic should not produce local output
      // --------------------------------------------------------
      local_mon.count_local_activity(10, local_activity_count);
      sb.check_next_no_local_activity();

      // Valid packet, so drop_cnt should stay 0.
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
