`timescale 1ns/1ps
// ============================================================
// Remote Backpressure Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send one valid REMOTE fragment.
//   Keep remote_rdy = 0 while remote_vld = 1.
//   Check that data_remote stays stable.
//
// Input packet:
//   payload = AA
//   input CRC = 12 34
//   FRAG_NUM = 1
//   SEQ_NUM  = 1
//
// Expected:
//   data_remote stays stable while remote_rdy = 0
//   final remote output = packed payload word + regenerated CRC word
//   no local output
//   drop_cnt = 0
// ============================================================

`ifndef REMOTE_BACKPRESSURE_TEST_SV
`define REMOTE_BACKPRESSURE_TEST_SV

class remote_backpressure_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(
    virtual bird_if vif,
    string name = "remote_backpressure_test"
  );
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run remote backpressure scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];
    byte unsigned merged_payload_q[$];

    logic [31:0] expected_remote_q[$];
    logic [31:0] actual_remote_q[$];

    bit stable_ok;
    logic [31:0] observed_first_word;

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
      tr = new("remote_backpressure_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // Valid remote fragment:
      //   payload   = AA
      //   frag_num  = 1
      //   seq_num   = 1
      //   input CRC = 12 34
      tr.set_remote_fragment(
        payload_q,
        5'd1,     // frag_num
        5'd1,     // seq_num
        16'h1234  // input CRC
      );

      tr.print();
	  cov.sample_transaction(tr);
	  cov.sample_remote_backpressure();

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction(tr);

      // --------------------------------------------------------
      // Build expected remote output
      // --------------------------------------------------------
      // Since this is one fragment:
      //   merged_payload = AA
      // Expected first remote word = 000000AA
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
      // Create remote backpressure
      // --------------------------------------------------------
      // remote_rdy stays low.
      // The DUT should keep the first remote word stable.
      // --------------------------------------------------------
      remote_mon.check_stable_under_backpressure(
        5,                   // number of cycles to hold backpressure
        stable_ok,
        observed_first_word
      );

      sb.check_remote_backpressure_stability(
        stable_ok,
        observed_first_word,
        expected_remote_q[0]
      );

      // --------------------------------------------------------
      // Capture actual remote output after backpressure check
      // --------------------------------------------------------
      // The first word was not consumed during the stability check,
      // so capture_words should still capture the first word.
      // --------------------------------------------------------
      remote_mon.capture_words(expected_remote_q.size(), actual_remote_q);

      // --------------------------------------------------------
      // Compare remote output using scoreboard
      // --------------------------------------------------------
      sb.check_next_remote_words("remote_backpressure_output", expected_remote_q);

      // --------------------------------------------------------
      // Remote traffic should not produce local output.
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