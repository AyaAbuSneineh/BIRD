`timescale 1ns/1ps
`ifndef REMOTE_THREE_FRAGMENT_3_1_2_TEST_SV
`define REMOTE_THREE_FRAGMENT_3_1_2_TEST_SV

class remote_three_fragment_3_1_2_test extends bird_base_test;

  function new(virtual bird_if vif, string name = "remote_three_fragment_3_1_2_test");
    super.new(vif, name);
  endfunction

  virtual task automatic run();
    bird_transaction frag0_tr;
    bird_transaction frag1_tr;
    bird_transaction frag2_tr;
    byte unsigned payload_q[$];
    byte unsigned merged_payload_q[$];
    logic [31:0] expected_remote_q[$];
    logic [31:0] actual_remote_q[$];
    int local_activity_count;
    int remote_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" REMOTE THREE FRAGMENT 3-1-2 TEST");
      $display("========================================");

      apply_reset();

      frag0_tr = new("remote_three_fragment_3_1_2_test_frag3_transaction");
      payload_q.delete();
      payload_q.push_back(8'h33);
      frag0_tr.set_remote_fragment(payload_q, 5'd3, 5'd1, 16'h3333);
      frag0_tr.print();
      cov.sample_transaction(frag0_tr);
      send_transaction(frag0_tr);

      remote_mon.count_remote_activity(5, remote_activity_count);
      sb.check_next_no_remote_activity();

      frag1_tr = new("remote_three_fragment_3_1_2_test_frag1_transaction");
      payload_q.delete();
      payload_q.push_back(8'h11);
      frag1_tr.set_remote_fragment(payload_q, 5'd1, 5'd1, 16'h1111);
      frag1_tr.print();
      cov.sample_transaction(frag1_tr);
      send_transaction(frag1_tr);

      remote_mon.count_remote_activity(5, remote_activity_count);
      sb.check_next_no_remote_activity();

      frag2_tr = new("remote_three_fragment_3_1_2_test_frag2_transaction");
      payload_q.delete();
      payload_q.push_back(8'h22);
      frag2_tr.set_remote_fragment(payload_q, 5'd2, 5'd1, 16'h2222);
      frag2_tr.print();
      cov.sample_transaction(frag2_tr);
      send_transaction(frag2_tr);

      merged_payload_q.delete();
      merged_payload_q.push_back(8'h11);
      merged_payload_q.push_back(8'h22);
      merged_payload_q.push_back(8'h33);

      build_expected_remote_output(merged_payload_q, expected_remote_q);
      remote_mon.capture_words(expected_remote_q.size(), actual_remote_q);
      sb.check_next_remote_words("remote_three_fragment_3_1_2_test_output", expected_remote_q);

      local_mon.count_local_activity(10, local_activity_count);
      sb.check_next_no_local_activity();
      sb.check_drop_count(vif.drop_cnt, 16'd0);

      repeat (5) @(posedge vif.clk);
      cov.sample_remote_three_fragment();
      final_report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif
