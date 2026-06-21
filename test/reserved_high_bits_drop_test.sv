`timescale 1ns/1ps
// ============================================================
// Reserved High Bits Drop Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send a packet with a reserved high cfg bit set.
//
// Input packet:
//   traffic_type = LOCAL
//   payload      = AA
//   CRC          = 12 34
//   FRAG_NUM     = 1
//   SEQ_NUM      = 1
//   cfg[29]      = 1   // invalid reserved bit in [31:29]
//
// Expected:
//   no local output
//   no remote output
//   drop_cnt = 1
//
// Spec reason:
//   cfg[31:29] are reserved and must be 0.
// ============================================================

`ifndef RESERVED_HIGH_BITS_DROP_TEST_SV
`define RESERVED_HIGH_BITS_DROP_TEST_SV

class reserved_high_bits_drop_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "reserved_high_bits_drop_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run reserved high bits invalid scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create a normally valid local transaction
      // --------------------------------------------------------
      tr = new("reserved_high_bits_drop_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // Start from valid local traffic:
      //   frag_num = 1
      //   seq_num  = 1
      tr.set_valid_local(payload_q, 16'h1234, 5'd1);

      // cfg[29] is inside reserved bits [31:29].
      tr.add_cfg_error_mask(32'h2000_0000);

      tr.print();
      cov.sample_transaction(tr);

      // --------------------------------------------------------
      // Send transaction to DUT
      // --------------------------------------------------------
      send_transaction(tr);

      // --------------------------------------------------------
      // Reserved-bit violation should drop the packet.
      // --------------------------------------------------------
      local_mon.count_local_activity(10, local_activity_count);
      remote_mon.count_remote_activity(10, remote_activity_count);

      sb.check_next_no_local_activity();
      sb.check_next_no_remote_activity();

      // Invalid packet, so drop_cnt should be 1.
      sb.check_drop_count(vif.drop_cnt, 16'd1);
      cov.sample_drop_seen(vif.drop_cnt);

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
