`timescale 1ns/1ps
// ============================================================
// Remote New Packet While Incomplete Drop Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   1. Start accumulating a REMOTE packet with SEQ_NUM = 1.
//      Use FRAG_NUM = 2 so fragment 1 is missing and the packet is
//      incomplete.
//   2. Send a new REMOTE packet start with SEQ_NUM = 2 and FRAG_NUM = 1
//      while the previous packet is still incomplete.
//
// Expected:
//   no local output
//   no remote output
//   drop_cnt increments from zero
//
// Spec reason:
//   Only one remote packet may be accumulated at a time. A new remote
//   packet start while the previous packet is incomplete is a drop
//   condition because the required fragment from the previous packet is
//   missing.
//
// Note:
//   The spec is clear that this is a drop condition. It is less explicit
//   about whether only the incomplete old packet or both packets are
//   counted. Therefore this test checks that drop_cnt is nonzero, not an
//   exact count.
// ============================================================

`ifndef REMOTE_NEW_PACKET_WHILE_INCOMPLETE_DROP_TEST_SV
`define REMOTE_NEW_PACKET_WHILE_INCOMPLETE_DROP_TEST_SV

class remote_new_packet_while_incomplete_drop_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "remote_new_packet_while_incomplete_drop_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run new-packet-while-incomplete scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction old_frag2_tr;
    bird_transaction new_frag1_tr;

    byte unsigned payload_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" REMOTE NEW PACKET WHILE INCOMPLETE DROP TEST");
      $display(" A new FRAG_NUM=1 packet arrives while a previous packet is incomplete.");
      $display(" If the DUT emits remote output or leaves drop_cnt at zero, report a possible DUT bug.");
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Old packet: fragment 2 arrives first, so fragment 1 is missing.
      // --------------------------------------------------------
      old_frag2_tr = new("remote_incomplete_old_seq1_frag2_transaction");

      payload_q.delete();
      payload_q.push_back(8'h22);

      old_frag2_tr.set_remote_fragment(
        payload_q,
        5'd2,     // fragment position 2
        5'd1,     // old packet sequence number
        16'h2222  // input CRC, consumed but not forwarded directly
      );

      old_frag2_tr.print();
      cov.sample_transaction(old_frag2_tr);

      send_transaction(old_frag2_tr);

      // Fragment 2 alone is incomplete and should not produce output.
      remote_mon.count_remote_activity(5, remote_activity_count);
      sb.check_next_no_remote_activity();

      // --------------------------------------------------------
      // New packet start arrives before the old packet completed.
      // --------------------------------------------------------
      new_frag1_tr = new("remote_new_seq2_frag1_while_old_incomplete_transaction");

      payload_q.delete();
      payload_q.push_back(8'h33);

      new_frag1_tr.set_remote_fragment(
        payload_q,
        5'd1,     // new packet start
        5'd2,     // different packet sequence number
        16'h3333  // input CRC, consumed but not forwarded directly
      );

      new_frag1_tr.print();
      cov.sample_transaction(new_frag1_tr);

      send_transaction(new_frag1_tr);

      // This is a drop condition. Watch both outputs at the same time
      // so a short unexpected pulse cannot be missed.
      fork
        local_mon.count_local_activity(20, local_activity_count);
        remote_mon.count_remote_activity(20, remote_activity_count);
      join

      sb.check_next_no_local_activity();
      sb.check_next_no_remote_activity();

      if (vif.drop_cnt == 16'd0) begin
        sb.record_fail("drop_cnt should increment when a new remote packet arrives while the previous packet is incomplete");
      end
      else begin
        sb.record_pass("drop_cnt incremented for new remote packet while previous packet incomplete");
        cov.sample_drop_seen(vif.drop_cnt);
      end

      repeat (5) @(posedge vif.clk);

      // Print final report.
      cov.sample_remote_new_packet_while_incomplete_drop();
      final_report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif
