`timescale 1ns/1ps
// ============================================================
// Local Basic Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send one valid LOCAL packet.
//
// Input packet:
//   payload = AA
//   CRC     = 12 34
//
// Expected:
//   local output = AA 12 34
//   drop_cnt     = 0
//   remote_vld   = 0
// ============================================================

`ifndef LOCAL_BASIC_TEST_SV
`define LOCAL_BASIC_TEST_SV

class local_basic_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(
    virtual bird_if vif,
    string name = "local_basic_test"
  );
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run local basic scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];
    byte unsigned expected_local_q[$];
    byte unsigned actual_local_q[$];

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create a valid local transaction
      // --------------------------------------------------------
      tr = new("local_basic_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // Valid local packet:
      //   traffic_type = LOCAL
      //   payload_len  = 1
      //   frag_num     = 1
      //   seq_num      = 1
      //   CRC          = 16'h1234
      tr.set_valid_local(payload_q, 16'h1234);
      tr.print();
	  cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction(tr);

      // --------------------------------------------------------
      // Build expected local output
      // --------------------------------------------------------
      build_expected_local_output(tr, expected_local_q);

      // --------------------------------------------------------
      // Capture actual local output
      // --------------------------------------------------------
      local_mon.capture_bytes(expected_local_q.size(), actual_local_q);

      // --------------------------------------------------------
      // Compare using scoreboard
      // --------------------------------------------------------
      sb.check_next_local_bytes("local_basic_output", expected_local_q);

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
