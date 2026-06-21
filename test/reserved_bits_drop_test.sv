`timescale 1ns/1ps
// ============================================================
// Reserved Bits Drop Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send a packet with a reserved bit set in cfg.
//
// Input packet:
//   traffic_type = LOCAL
//   payload      = AA
//   CRC          = 12 34
//   FRAG_NUM     = 1
//   SEQ_NUM      = 1
//   cfg[1]       = 1   // invalid reserved bit
//
// Expected:
//   no local output
//   no remote output
//   drop_cnt = 1
// ============================================================

`ifndef RESERVED_BITS_DROP_TEST_SV
`define RESERVED_BITS_DROP_TEST_SV

class reserved_bits_drop_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "reserved_bits_drop_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run reserved bits invalid scenario
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
      // Create a normally valid local transaction
      // --------------------------------------------------------
      tr = new("reserved_bits_drop_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // This is valid local traffic at first:
      //   frag_num = 1
      //   seq_num  = 1
      tr.set_valid_local(payload_q, 16'h1234);

      // cfg[1] is inside reserved bits [7:1].
      tr.add_cfg_error_mask(32'h0000_0002);

      tr.print();
	  cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction(tr);

      // --------------------------------------------------------
      // Since cfg has a reserved bit set, packet should be dropped.
      // Watch for local output to make sure nothing appears.
      // --------------------------------------------------------
      local_mon.count_local_activity(10, local_activity_count);

      // --------------------------------------------------------
      // Compare using scoreboard
      // --------------------------------------------------------
      sb.check_next_no_local_activity();

      // Invalid packet, so drop_cnt should be 1.
      sb.check_drop_count(vif.drop_cnt, 16'd1);
	  cov.sample_drop_seen(vif.drop_cnt);

      // Invalid packet should not activate remote output.
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