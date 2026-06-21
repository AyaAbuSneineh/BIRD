`timescale 1ns/1ps
// ============================================================
// Local Multi-Byte Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send one valid LOCAL packet with more than one payload byte.
//
// Input packet:
//   payload = AA BB CC DD
//   CRC     = 55 66
//								  
// Expected:
//   local output = AA BB CC DD 55 66
//   drop_cnt     = 0
//   remote_vld   = 0
// ============================================================

`ifndef LOCAL_MULTI_BYTE_TEST_SV
`define LOCAL_MULTI_BYTE_TEST_SV

class local_multi_byte_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(
    virtual bird_if vif,
    string name = "local_multi_byte_test"
  );
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run local multi-byte scenario
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
      tr = new("local_multi_byte_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);
      payload_q.push_back(8'hBB);
      payload_q.push_back(8'hCC);
      payload_q.push_back(8'hDD);

      // Valid local packet:
      //   traffic_type = LOCAL
      //   payload_len  = 4
      //   frag_num     = 1
      //   seq_num      = 1
      //   CRC          = 16'h5566
      tr.set_valid_local(payload_q, 16'h5566);
      tr.print();
	  cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction_with_crc_boundary_check(
        tr,
        "local_multi_byte_payload_crc_boundary"
      );

      // --------------------------------------------------------
      // Build expected local output
      // --------------------------------------------------------
      // For local traffic, expected output is:
      //   payload bytes + CRC bytes unchanged
      // --------------------------------------------------------
      build_expected_local_output(tr, expected_local_q);

      // --------------------------------------------------------
      // Capture actual local output
      // --------------------------------------------------------
      local_mon.capture_bytes(expected_local_q.size(), actual_local_q);

      // --------------------------------------------------------
      // Compare using scoreboard
      // --------------------------------------------------------
      sb.check_next_local_bytes("local_multi_byte_output", expected_local_q);

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