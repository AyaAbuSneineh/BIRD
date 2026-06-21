`timescale 1ns/1ps
// ============================================================
// Local Backpressure Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send one valid LOCAL packet.
//   Keep local_rdy = 0 while local_vld = 1.
//   Check that data_local stays stable.
//
// Input packet:
//   payload = AA
//   CRC     = 12 34
//
// Expected:
//   data_local stays stable while local_rdy = 0
//   final local output = AA 12 34
//   drop_cnt = 0
//   remote_vld = 0
// ============================================================

`ifndef LOCAL_BACKPRESSURE_TEST_SV
`define LOCAL_BACKPRESSURE_TEST_SV

class local_backpressure_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "local_backpressure_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run local backpressure scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];
    byte unsigned expected_local_q[$];
    byte unsigned actual_local_q[$];

    bit stable_ok;
    byte unsigned observed_first_byte;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create a valid local transaction
      // --------------------------------------------------------
      tr = new("local_backpressure_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // Valid local packet:
      //   payload = AA
      //   CRC     = 12 34
      //
      // This test uses payload_len = 1 to isolate the local
      // backpressure behavior from the known payload/CRC boundary
      // issue that appears when payload_len > 1.
      tr.set_valid_local(payload_q, 16'h1234);
      tr.print();

      cov.sample_transaction(tr);
      cov.sample_local_backpressure();

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction_with_crc_boundary_check(
        tr,
        "local_backpressure_payload_crc_boundary"
      );

      // --------------------------------------------------------
      // Create local backpressure
      // --------------------------------------------------------
      // local_rdy stays low.
      // The DUT should keep the first output byte stable.
      // --------------------------------------------------------
      local_mon.check_stable_under_backpressure(
        5,                  // number of cycles to hold backpressure
        stable_ok,
        observed_first_byte
      );

      sb.check_local_backpressure_stability(
        stable_ok,
        observed_first_byte,
        8'hAA
      );

      // --------------------------------------------------------
      // Build expected local output
      // --------------------------------------------------------
      build_expected_local_output(tr, expected_local_q);

      // --------------------------------------------------------
      // Capture actual output after backpressure check
      // --------------------------------------------------------
      // The first byte was not consumed during the stability check,
      // so capture_bytes should still capture AA first.
      // --------------------------------------------------------
      local_mon.capture_bytes(expected_local_q.size(), actual_local_q);

      // --------------------------------------------------------
      // Compare using scoreboard
      // --------------------------------------------------------
      sb.check_next_local_bytes("local_backpressure_output", expected_local_q);

      // Valid packet, so drop_cnt should stay 0.
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
