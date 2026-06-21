`timescale 1ns/1ps
// ============================================================
// Remote Two-Fragment In-Order Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send one valid REMOTE packet made of two fragments.
//   The fragments arrive in order:
//     1. FRAG_NUM = 1
//     2. FRAG_NUM = 2
//
// Input packet:
//   traffic_type = REMOTE
//   SEQ_NUM      = 1 for both fragments
//
//   fragment 1 payload = 11
//   fragment 2 payload = 22
//
// Expected:
//   no remote output after fragment 1 alone
//   final merged payload order = fragment 1, then fragment 2
//   remote output word 0 = 00002211
//   remote output word 1 = {16'h0000, regenerated_crc}
//   no local output
//   drop_cnt = 0
//
// Spec reason:
//   Remote fragments with the same SEQ_NUM belong to the same packet.
//   They must be buffered, reordered by FRAG_NUM, merged, and sent with
//   a regenerated CRC16.
//
// Note:
//   The PDF does not provide an explicit last-fragment marker. This test
//   treats the driven two-fragment sequence as one packet and verifies
//   that the DUT does not emit fragment 1 as a complete packet too early.
// ============================================================

`ifndef REMOTE_TWO_FRAGMENT_IN_ORDER_TEST_SV
`define REMOTE_TWO_FRAGMENT_IN_ORDER_TEST_SV

class remote_two_fragment_in_order_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "remote_two_fragment_in_order_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run remote in-order two-fragment scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction frag1_tr;
    bird_transaction frag2_tr;

    byte unsigned frag1_payload_q[$];
    byte unsigned frag2_payload_q[$];
    byte unsigned merged_payload_q[$];

    logic [31:0] expected_remote_q[$];
    logic [31:0] actual_remote_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" REMOTE TWO-FRAGMENT IN-ORDER TEST");
      $display(" Fragments arrive as FRAG_NUM=1 then FRAG_NUM=2.");
      $display(" If the DUT emits fragment 1 early, drops fragment 2, or fails to merge, report a possible DUT/spec issue.");
      $display("========================================");

      // Apply reset before starting the test.
      apply_reset();

      // --------------------------------------------------------
      // Fragment 1 arrives first
      // --------------------------------------------------------
      frag1_tr = new("remote_two_fragment_in_order_frag1_transaction");

      frag1_payload_q.delete();
      frag1_payload_q.push_back(8'h11);

      frag1_tr.set_remote_fragment(
        frag1_payload_q,
        5'd1,     // fragment position 1
        5'd1,     // packet sequence number
        16'h1111  // input CRC, consumed but not forwarded directly
      );

      frag1_tr.print();
      cov.sample_transaction(frag1_tr);

      send_transaction(frag1_tr);

      // This test intentionally models a two-fragment packet. Fragment 1
      // alone should not be emitted as a complete remote packet.
      remote_mon.count_remote_activity(5, remote_activity_count);
      sb.check_next_no_remote_activity();

      // --------------------------------------------------------
      // Fragment 2 completes the packet
      // --------------------------------------------------------
      frag2_tr = new("remote_two_fragment_in_order_frag2_transaction");

      frag2_payload_q.delete();
      frag2_payload_q.push_back(8'h22);

      frag2_tr.set_remote_fragment(
        frag2_payload_q,
        5'd2,     // fragment position 2
        5'd1,     // same packet sequence number
        16'h2222  // input CRC, consumed but not forwarded directly
      );

      frag2_tr.print();
      cov.sample_transaction(frag2_tr);

      send_transaction(frag2_tr);

      // --------------------------------------------------------
      // Build expected merged output in FRAG_NUM order.
      // --------------------------------------------------------
      merged_payload_q.delete();
      foreach (frag1_payload_q[i]) begin
        merged_payload_q.push_back(frag1_payload_q[i]);
      end
      foreach (frag2_payload_q[i]) begin
        merged_payload_q.push_back(frag2_payload_q[i]);
      end

      build_expected_remote_output(merged_payload_q, expected_remote_q);

      $display("[%0t] %s: expected remote words:", $time, name);
      foreach (expected_remote_q[i]) begin
        $display("  expected_remote_q[%0d] = %08h",
                 i, expected_remote_q[i]);
      end

      // --------------------------------------------------------
      // Capture and compare remote output.
      // --------------------------------------------------------
      remote_mon.capture_words(expected_remote_q.size(), actual_remote_q);

      sb.check_next_remote_words("remote_two_fragment_in_order_output", expected_remote_q);

      // Remote traffic should not produce local output.
      local_mon.count_local_activity(10, local_activity_count);
      sb.check_next_no_local_activity();

      // Spec-valid packet, so drop_cnt should stay 0.
      sb.check_drop_count(vif.drop_cnt, 16'd0);

      repeat (5) @(posedge vif.clk);

      // Print final report.
      cov.sample_remote_two_fragment_in_order();
      final_report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif
