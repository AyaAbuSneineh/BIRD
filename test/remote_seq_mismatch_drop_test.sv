`timescale 1ns/1ps
// ============================================================
// Remote SEQ_NUM Mismatch Drop Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   1. Start accumulating a REMOTE packet with SEQ_NUM = 1.
//      Use FRAG_NUM = 2 so the packet is incomplete and fragment 1
//      is still required.
//   2. Send another REMOTE fragment with SEQ_NUM = 2 while the
//      first packet is still incomplete.
//
// Expected:
//   no local output
//   no remote output
//   drop_cnt increments from zero
//
// Spec reason:
//   Only one remote packet, identified by SEQ_NUM, may be accumulated
//   at a time. A fragment with mismatched SEQ_NUM while another packet
//   is being accumulated is a drop condition.
//
// Note:
//   The spec is clear that this is a drop. It is less explicit about
//   whether the old incomplete packet, the new fragment, or both are
//   counted. Therefore this directed test checks that drop_cnt is
//   nonzero, not an exact count.
// ============================================================

`ifndef REMOTE_SEQ_MISMATCH_DROP_TEST_SV
`define REMOTE_SEQ_MISMATCH_DROP_TEST_SV

class remote_seq_mismatch_drop_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "remote_seq_mismatch_drop_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run remote mismatched SEQ_NUM scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction seq1_frag2_tr;
    bird_transaction seq2_frag2_tr;

    byte unsigned payload_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" REMOTE SEQ_NUM MISMATCH DROP TEST");
      $display(" A different SEQ_NUM arrives while another packet is incomplete.");
      $display(" If the DUT emits remote output or leaves drop_cnt at zero, report a possible DUT bug.");
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Fragment from packet SEQ_NUM = 1.
      // FRAG_NUM = 2 means fragment 1 is required before output.
      // --------------------------------------------------------
      seq1_frag2_tr = new("remote_seq_mismatch_seq1_frag2_transaction");

      payload_q.delete();
      payload_q.push_back(8'h22);

      seq1_frag2_tr.set_remote_fragment(
        payload_q,
        5'd2,     // fragment position 2
        5'd1,     // active packet sequence number
        16'h2222  // input CRC, consumed but not forwarded directly
      );

      seq1_frag2_tr.print();
      cov.sample_transaction(seq1_frag2_tr);

      send_transaction(seq1_frag2_tr);

      // Fragment 2 alone is incomplete and should not produce output.
      remote_mon.count_remote_activity(5, remote_activity_count);
      sb.check_next_no_remote_activity();

      // --------------------------------------------------------
      // Mismatched SEQ_NUM arrives while SEQ_NUM = 1 is incomplete.
      // --------------------------------------------------------
      seq2_frag2_tr = new("remote_seq_mismatch_seq2_frag2_transaction");

      payload_q.delete();
      payload_q.push_back(8'h33);

      seq2_frag2_tr.set_remote_fragment(
        payload_q,
        5'd2,     // fragment position 2
        5'd2,     // mismatched packet sequence number
        16'h3333  // input CRC, consumed but not forwarded directly
      );

      seq2_frag2_tr.print();
      cov.sample_transaction(seq2_frag2_tr);

      send_transaction(seq2_frag2_tr);

      // Mismatched sequence should not produce either output stream.
      // Watch both outputs at the same time so a short unexpected pulse
      // on one stream cannot be missed while the other stream is checked.
      fork
        local_mon.count_local_activity(20, local_activity_count);
        remote_mon.count_remote_activity(20, remote_activity_count);
      join

      sb.check_next_no_local_activity();
      sb.check_next_no_remote_activity();

      if (vif.drop_cnt == 16'd0) begin
        sb.record_fail("drop_cnt should increment for remote SEQ_NUM mismatch while accumulating");
      end
      else begin
        sb.record_pass("drop_cnt incremented for remote SEQ_NUM mismatch while accumulating");
        cov.sample_drop_seen(vif.drop_cnt);
      end

      repeat (5) @(posedge vif.clk);

      // Print final report.
      cov.sample_remote_seq_mismatch_drop();
      final_report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif
