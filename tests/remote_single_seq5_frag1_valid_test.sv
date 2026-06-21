`timescale 1ns/1ps
`ifndef REMOTE_SINGLE_SEQ5_FRAG1_VALID_TEST_SV
`define REMOTE_SINGLE_SEQ5_FRAG1_VALID_TEST_SV

class remote_single_seq5_frag1_valid_test extends bird_base_test;

  function new(virtual bird_if vif, string name = "remote_single_seq5_frag1_valid_test");
    super.new(vif, name);
  endfunction

  virtual task automatic run();
    bird_transaction tr;
    byte unsigned payload_q[$];
    logic [31:0] expected_remote_q[$];
    logic [31:0] actual_remote_q[$];
    int local_activity_count;

    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display(" REMOTE SINGLE FRAGMENT SEQ_NUM=5 VALID TEST");
      $display("========================================");

      apply_reset();

      tr = new("remote_single_seq5_frag1_valid_test_transaction");
      payload_q.delete();
      payload_q.push_back(8'hC1);
      tr.set_remote_fragment(payload_q, 5'd1, 5'd5, 16'h1122);
      tr.print();
      cov.sample_transaction(tr);

      build_expected_remote_output(tr.payload, expected_remote_q);
      send_transaction(tr);

      remote_mon.capture_words(expected_remote_q.size(), actual_remote_q);
      sb.check_next_remote_words("remote_single_seq5_frag1_valid_test_output", expected_remote_q);
      local_mon.count_local_activity(5, local_activity_count);
      sb.check_next_no_local_activity();
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
