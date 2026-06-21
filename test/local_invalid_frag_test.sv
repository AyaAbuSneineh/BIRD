`timescale 1ns/1ps
// ============================================================
// Local Invalid FRAG Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send a LOCAL packet with invalid FRAG_NUM.
//
// Input packet:
//   traffic_type = LOCAL
//   payload      = AA
//   CRC          = 12 34
//   FRAG_NUM     = 2   // invalid for local traffic
//   SEQ_NUM      = 1
//
// Expected:
//   no local output
//   no remote output
//   drop_cnt = 1
// ============================================================

`ifndef LOCAL_INVALID_FRAG_TEST_SV
`define LOCAL_INVALID_FRAG_TEST_SV

class local_invalid_frag_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(
    virtual bird_if vif,
    string name = "local_invalid_frag_test"
  );
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run invalid local FRAG scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];
    int local_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create an invalid local transaction
      // --------------------------------------------------------
      tr = new("local_invalid_frag_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // Local traffic, seq_num = 1, but frag_num = 2.
      // This is invalid for local traffic according to the PDF spec:
      // local traffic consists of a single fragment and FRAG_NUM must be 1.
      tr.set_local_custom(payload_q,
        5'd2,     // invalid frag_num for local traffic
        5'd1,     // valid seq_num for local traffic
        16'h1234  // input CRC
      );

      tr.print(); 
	  cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction(tr);

      // --------------------------------------------------------
      // Since packet is invalid, local output should not appear.
      // Watch for a few cycles to make sure nothing comes out.
      // --------------------------------------------------------
      local_mon.count_local_activity(10, local_activity_count);

      // --------------------------------------------------------
      // Compare using scoreboard
      // --------------------------------------------------------
      sb.check_next_no_local_activity();

      // Invalid packet, so drop_cnt should be 1.
      sb.check_drop_count(vif.drop_cnt, 16'd1);
	  cov.sample_drop_seen(vif.drop_cnt);

      // Invalid local packet should not activate remote output.
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
