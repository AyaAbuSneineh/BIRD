`timescale 1ns/1ps
// ============================================================
// Local/Remote Switching Test
// ------------------------------------------------------------
// This test extends bird_base_test.
//
// Scenario:
//   Send valid LOCAL, then valid REMOTE, then valid LOCAL traffic in
//   one test without reset between packets.
//
// Expected:
//   LOCAL packets appear only on the local output
//   REMOTE packet appears only on the remote output
//   drop_cnt remains 0
//
// Spec reason:
//   cfg[0] selects LOCAL vs REMOTE routing per packet. A valid packet on
//   one path must not poison later packets on the other path.
// ============================================================

`ifndef LOCAL_REMOTE_SWITCHING_TEST_SV
`define LOCAL_REMOTE_SWITCHING_TEST_SV

class local_remote_switching_test extends bird_base_test;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "local_remote_switching_test");
    super.new(vif, name);
  endfunction


  // ------------------------------------------------------------
  // Run local/remote/local switching scenario
  // ------------------------------------------------------------
  virtual task automatic run();
    bird_transaction local1_tr;
    bird_transaction remote_tr;
    bird_transaction local2_tr;

    byte unsigned payload_q[$];
    byte unsigned expected_local_q[$];
    byte unsigned actual_local_q[$];
    byte unsigned merged_payload_q[$];

    logic [31:0] expected_remote_q[$];
    logic [31:0] actual_remote_q[$];

    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" LOCAL/REMOTE SWITCHING TEST");
      $display(" Valid LOCAL, then REMOTE, then LOCAL traffic must route independently.");
      $display("========================================");

      apply_reset();

      // --------------------------------------------------------
      // Packet 1: valid local.
      // --------------------------------------------------------
      local1_tr = new("local_remote_switching_local1_transaction");

      payload_q.delete();
      payload_q.push_back(8'hA1);

      local1_tr.set_valid_local(payload_q, 16'h1111, 5'd1);

      local1_tr.print();
      cov.sample_transaction(local1_tr);

      send_transaction(local1_tr);

      build_expected_local_output(local1_tr, expected_local_q);
      fork
        local_mon.capture_bytes(expected_local_q.size(), actual_local_q);
        remote_mon.count_remote_activity(20, remote_activity_count);
      join
      sb.check_next_local_bytes("local_remote_switching_local1_output", expected_local_q);

      sb.check_next_no_remote_activity();
      sb.check_drop_count(vif.drop_cnt, 16'd0);

      // --------------------------------------------------------
      // Packet 2: valid remote.
      // --------------------------------------------------------
      remote_tr = new("local_remote_switching_remote_transaction");

      payload_q.delete();
      payload_q.push_back(8'hB2);

      remote_tr.set_remote_fragment(
        payload_q,
        5'd1,     // single-fragment remote packet
        5'd1,     // valid sequence number
        16'h2222  // input CRC, consumed but not forwarded directly
      );

      remote_tr.print();
      cov.sample_transaction(remote_tr);

      send_transaction(remote_tr);

      merged_payload_q.delete();
      foreach (payload_q[i]) begin
        merged_payload_q.push_back(payload_q[i]);
      end

      build_expected_remote_output(merged_payload_q, expected_remote_q);
      fork
        remote_mon.capture_words(expected_remote_q.size(), actual_remote_q);
        local_mon.count_local_activity(20, local_activity_count);
      join
      sb.check_next_remote_words("local_remote_switching_remote_output", expected_remote_q);

      sb.check_next_no_local_activity();
      sb.check_drop_count(vif.drop_cnt, 16'd0);

      // --------------------------------------------------------
      // Packet 3: another valid local after remote.
      // --------------------------------------------------------
      local2_tr = new("local_remote_switching_local2_transaction");

      payload_q.delete();
      payload_q.push_back(8'hC3);

      local2_tr.set_valid_local(payload_q, 16'h3333, 5'd1);

      local2_tr.print();
      cov.sample_transaction(local2_tr);

      send_transaction(local2_tr);

      build_expected_local_output(local2_tr, expected_local_q);
      fork
        local_mon.capture_bytes(expected_local_q.size(), actual_local_q);
        remote_mon.count_remote_activity(20, remote_activity_count);
      join
      sb.check_next_local_bytes("local_remote_switching_local2_output", expected_local_q);

      sb.check_next_no_remote_activity();
      sb.check_drop_count(vif.drop_cnt, 16'd0);

      repeat (5) @(posedge vif.clk);

      final_report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif
