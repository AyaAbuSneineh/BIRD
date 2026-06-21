`timescale 1ns/1ps
// ============================================================
// Remote Drop Recovery Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   1. Send an invalid REMOTE packet with SEQ_NUM = 0.
//   2. Verify it drops.
//   3. Send a valid REMOTE packet without reset.
//
// Expected:
//   invalid remote packet produces no output and increments drop_cnt
//   valid remote packet after the drop forwards normally
//   drop_cnt remains at 1 after the valid packet
//
// Spec reason:
//   drop_cnt accumulates dropped packets until reset. A dropped remote
//   packet must not poison later valid remote traffic.
// ============================================================

`ifndef REMOTE_DROP_RECOVERY_TEST_SV
`define REMOTE_DROP_RECOVERY_TEST_SV

class remote_drop_recovery_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "remote_drop_recovery_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run remote drop recovery scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction invalid_tr;
    bird_transaction valid_tr;

    byte unsigned payload_q[$];
    byte unsigned merged_payload_q[$];

    logic [31:0] expected_remote_q[$];
    logic [31:0] actual_remote_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" REMOTE DROP RECOVERY TEST");
      $display(" A valid remote packet after an invalid remote packet must still forward.");
      $display("========================================");

      apply_reset();

      // --------------------------------------------------------
      // Packet 1: invalid remote SEQ_NUM = 0.
      // --------------------------------------------------------
      invalid_tr = new("remote_drop_recovery_invalid_seq0_transaction");

      payload_q.delete();
      payload_q.push_back(8'h44);

      invalid_tr.set_remote_fragment(
        payload_q,
        5'd1,     // valid fragment number
        5'd0,     // invalid sequence number
        16'h4444
      );

      invalid_tr.print();
      cov.sample_transaction(invalid_tr);

      send_transaction(invalid_tr);

      fork
        local_mon.count_local_activity(10, local_activity_count);
        remote_mon.count_remote_activity(10, remote_activity_count);
      join

      sb.check_next_no_local_activity();
      sb.check_next_no_remote_activity();
      sb.check_drop_count(vif.drop_cnt, 16'd1);
      cov.sample_drop_seen(vif.drop_cnt);

      // --------------------------------------------------------
      // Packet 2: valid remote packet after the drop.
      // --------------------------------------------------------
      valid_tr = new("remote_drop_recovery_valid_remote_transaction");

      payload_q.delete();
      payload_q.push_back(8'h55);

      valid_tr.set_remote_fragment(
        payload_q,
        5'd1,     // single-fragment remote packet
        5'd1,     // valid sequence number
        16'h5555
      );

      valid_tr.print();
      cov.sample_transaction(valid_tr);

      send_transaction(valid_tr);

      merged_payload_q.delete();
      foreach (payload_q[i]) begin
        merged_payload_q.push_back(payload_q[i]);
      end

      build_expected_remote_output(merged_payload_q, expected_remote_q);
      fork
        remote_mon.capture_words(expected_remote_q.size(), actual_remote_q);
        local_mon.count_local_activity(20, local_activity_count);
      join

      sb.check_next_remote_words("remote_drop_recovery_valid_output", expected_remote_q);

      sb.check_next_no_local_activity();

      // Valid packet after a drop should not increment drop_cnt again.
      sb.check_drop_count(vif.drop_cnt, 16'd1);

      repeat (5) @(posedge vif.clk);

      final_report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif
