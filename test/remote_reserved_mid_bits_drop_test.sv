`timescale 1ns/1ps
// ============================================================
// Remote Reserved Middle Bits Drop Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send a REMOTE packet with a reserved middle cfg bit set.
//
// Input packet:
//   traffic_type = REMOTE
//   payload      = AA
//   input CRC    = 12 34
//   FRAG_NUM     = 1
//   SEQ_NUM      = 1
//   cfg[21]      = 1   // invalid reserved bit in [23:21]
//
// Expected:
//   no local output
//   no remote output
//   drop_cnt = 1
//
// Spec reason:
//   cfg[23:21] are reserved and must be 0 for all traffic types.
// ============================================================

`ifndef REMOTE_RESERVED_MID_BITS_DROP_TEST_SV
`define REMOTE_RESERVED_MID_BITS_DROP_TEST_SV

class remote_reserved_mid_bits_drop_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "remote_reserved_mid_bits_drop_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run remote reserved middle bits invalid scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction tr;

    byte unsigned payload_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" REMOTE RESERVED MIDDLE BITS DROP TEST");
      $display(" cfg[23:21] must be zero for remote traffic.");
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Create a normally valid remote transaction
      // --------------------------------------------------------
      tr = new("remote_reserved_mid_bits_drop_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      tr.set_remote_fragment(
        payload_q,
        5'd1,     // valid frag_num
        5'd1,     // valid seq_num
        16'h1234  // input CRC
      );

      // cfg[21] is inside reserved bits [23:21].
      tr.add_cfg_error_mask(32'h0020_0000);

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
