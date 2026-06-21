`timescale 1ns/1ps
`ifndef REMOTE_FRAG5_SEQ3_NEXT_SV
`define REMOTE_FRAG5_SEQ3_NEXT_SV

class remote_frag5_seq3_next extends bird_base_test;

  function new(virtual bird_if vif, string name = "remote_frag5_seq3_next");
    super.new(vif, name);
  endfunction

  virtual task automatic run();
    bird_transaction old_frag_tr;
    bird_transaction new_frag_tr;

    byte unsigned payload_q[$];

    int local_activity_count;
    int remote_activity_count;

    logic [15:0] expected_drop_cnt;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" REMOTE SEQ MISMATCH SAME FRAG DROP TEST");
      $display(" Spec expected: mismatched SEQ while old remote packet incomplete must be dropped.");
      $display("========================================");

      apply_reset();

      // First fragment starts an incomplete remote packet:
      // SEQ=1, FRAG=2. This means fragment 1 is still missing.
      old_frag_tr = new("remote_old_seq1_frag2_incomplete_transaction");

      payload_q.delete();
      payload_q.push_back(8'h11);

      old_frag_tr.set_remote_fragment(
        payload_q,
        5'd2,      // FRAG_NUM = 2
        5'd1,      // SEQ_NUM  = 1
        16'h1111
      );

      old_frag_tr.print();
      cov.sample_transaction(old_frag_tr);

      send_transaction(old_frag_tr);

      remote_mon.count_remote_activity(5, remote_activity_count);
      sb.check_next_no_remote_activity();

      // Second fragment has different SEQ while old packet is incomplete.
      // According to spec, this must be dropped.
      expected_drop_cnt = vif.drop_cnt + 16'd1;

      new_frag_tr = new("remote_new_seq2_frag2_mismatch_transaction");

      payload_q.delete();
      payload_q.push_back(8'h22);

      new_frag_tr.set_remote_fragment(
        payload_q,
        5'd3,      // FRAG_NUM = 2
        5'd5,      // SEQ_NUM  = 2, mismatched with active SEQ=1
        16'h2222
      );

      new_frag_tr.print();
      cov.sample_transaction(new_frag_tr);

      send_transaction(new_frag_tr);

      fork
        local_mon.count_local_activity(15, local_activity_count);
        remote_mon.count_remote_activity(15, remote_activity_count);
      join

      sb.check_next_no_local_activity();
      sb.check_next_no_remote_activity();

      sb.check_drop_count(vif.drop_cnt, expected_drop_cnt);
      cov.sample_drop_seen(vif.drop_cnt);

      repeat (5) @(posedge vif.clk);

      final_report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif

