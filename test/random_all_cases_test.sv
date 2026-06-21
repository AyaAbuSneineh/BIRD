`timescale 1ns/1ps
`ifndef RANDOM_ALL_CASES_TEST_SV
`define RANDOM_ALL_CASES_TEST_SV

class random_all_cases_test extends bird_base_test;

  int unsigned random_case_total;
  int unsigned random_case_pass;
  int unsigned random_case_fail;
  int unsigned fail_before_case;

  function new(virtual bird_if vif, string name = "random_all_cases_test");
    super.new(vif, name);
    random_case_total = 0;
    random_case_pass  = 0;
    random_case_fail  = 0;
    fail_before_case  = 0;
  endfunction

  function void begin_random_case(input string case_name);
    random_case_total++;
    fail_before_case = sb.fail_count;

    $display("------------------------------------------------------------");
    $display(" RANDOM_CASE_START : %s", case_name);
    $display("------------------------------------------------------------");
  endfunction

  function void end_random_case(input string case_name);
    if (sb.fail_count == fail_before_case) begin
      random_case_pass++;
      $display(" RANDOM_CASE_RESULT : PASS : %s", case_name);
    end
    else begin
      random_case_fail++;
      $display(" RANDOM_CASE_RESULT : FAIL : %s", case_name);
    end

    $display("------------------------------------------------------------");
  endfunction

  function void random_case_report();
    $display("========================================");
    $display(" Random Cases Final Report");
    $display(" RANDOM_CASES_TOTAL : %0d", random_case_total);
    $display(" RANDOM_CASES_PASS  : %0d", random_case_pass);
    $display(" RANDOM_CASES_FAIL  : %0d", random_case_fail);

    if (random_case_fail == 0) begin
      $display(" RANDOM_TEST_RESULT : PASS");
    end
    else begin
      $display(" RANDOM_TEST_RESULT : FAIL");
    end

    $display("========================================");
  endfunction

  task automatic run_valid_local_case(input bird_transaction tr, input string label);
    byte unsigned expected_local_q[$];
    byte unsigned actual_local_q[$];
    int remote_activity_count;
    logic [15:0] expected_drop_cnt;

    apply_reset();

    cov.sample_transaction(tr);
    expected_drop_cnt = vif.drop_cnt;

    build_expected_local_output(tr, expected_local_q);
    // send_transaction(tr);
    send_transaction_with_crc_boundary_check(tr, "random_all_cases_payload_crc_boundary");
    local_mon.capture_bytes(expected_local_q.size(), actual_local_q);
    sb.check_next_local_bytes(label, expected_local_q);

    remote_mon.count_remote_activity(3, remote_activity_count);
    sb.check_next_no_remote_activity();

    sb.check_drop_count(vif.drop_cnt, expected_drop_cnt);

    repeat (3) @(posedge vif.clk);
  endtask

  task automatic run_valid_remote_case(input bird_transaction tr, input string label);
    logic [31:0] expected_remote_q[$];
    logic [31:0] actual_remote_q[$];
    int local_activity_count;
    logic [15:0] expected_drop_cnt;

    apply_reset();

    cov.sample_transaction(tr);
    expected_drop_cnt = vif.drop_cnt;

    build_expected_remote_output(tr.payload, expected_remote_q);
    send_transaction(tr);

    remote_mon.capture_words(expected_remote_q.size(), actual_remote_q);
    sb.check_next_remote_words(label, expected_remote_q);

    local_mon.count_local_activity(3, local_activity_count);
    sb.check_next_no_local_activity();

    sb.check_drop_count(vif.drop_cnt, expected_drop_cnt);

    repeat (3) @(posedge vif.clk);
  endtask

  task automatic run_drop_case(input bird_transaction tr, input string label);
    int local_activity_count;
    int remote_activity_count;
    logic [15:0] expected_drop_cnt;

    apply_reset();

    cov.sample_transaction(tr);
    expected_drop_cnt = vif.drop_cnt + 16'd1;

    send_transaction(tr);

    fork
      local_mon.count_local_activity(10, local_activity_count);
      remote_mon.count_remote_activity(10, remote_activity_count);
    join

    sb.check_next_no_local_activity();
    sb.check_next_no_remote_activity();

    sb.check_drop_count(vif.drop_cnt, expected_drop_cnt);
    cov.sample_drop_seen(vif.drop_cnt);

    repeat (3) @(posedge vif.clk);
  endtask

  virtual task automatic run();
    bird_transaction tr;
    int unsigned num_per_case;

    num_per_case = 2;
    void'($value$plusargs("NUM_PER_CASE=%d", num_per_case));

    $display("========================================");
    $display(" Starting %s", name);
    $display(" NUM_PER_CASE = %0d", num_per_case);
    $display("========================================");

    for (int i = 0; i < num_per_case; i++) begin

      begin_random_case($sformatf("random_local_payload_data[%0d]", i));
      env.gen.create_random_local_payload_data_transaction(tr, i);
      run_valid_local_case(tr, $sformatf("random local payload data %0d", i));
      end_random_case($sformatf("random_local_payload_data[%0d]", i));

      begin_random_case($sformatf("random_local_seq_num[%0d]", i));
      env.gen.create_random_local_seq_num_transaction(tr, i);
      run_valid_local_case(tr, $sformatf("random local seq num %0d", i));
      end_random_case($sformatf("random_local_seq_num[%0d]", i));

      begin_random_case($sformatf("random_local_payload_len[%0d]", i));
      env.gen.create_random_local_payload_len_transaction(tr, i);
      run_valid_local_case(tr, $sformatf("random local payload len %0d", i));
      end_random_case($sformatf("random_local_payload_len[%0d]", i));

      begin_random_case($sformatf("random_remote_payload_data[%0d]", i));
      env.gen.create_random_remote_payload_data_transaction(tr, i);
      run_valid_remote_case(tr, $sformatf("random remote payload data %0d", i));
      end_random_case($sformatf("random_remote_payload_data[%0d]", i));

      begin_random_case($sformatf("random_remote_seq_num[%0d]", i));
      env.gen.create_random_remote_seq_num_transaction(tr, i);
      run_valid_remote_case(tr, $sformatf("random remote seq num %0d", i));
      end_random_case($sformatf("random_remote_seq_num[%0d]", i));

      begin_random_case($sformatf("random_remote_payload_len[%0d]", i));
      env.gen.create_random_remote_payload_len_transaction(tr, i);
      run_valid_remote_case(tr, $sformatf("random remote payload len %0d", i));
      end_random_case($sformatf("random_remote_payload_len[%0d]", i));

      begin_random_case($sformatf("random_local_seq_zero_drop[%0d]", i));
      env.gen.create_random_local_seq_zero_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random local seq zero drop %0d", i));
      end_random_case($sformatf("random_local_seq_zero_drop[%0d]", i));

      begin_random_case($sformatf("random_local_frag_zero_drop[%0d]", i));
      env.gen.create_random_local_frag_zero_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random local frag zero drop %0d", i));
      end_random_case($sformatf("random_local_frag_zero_drop[%0d]", i));

      begin_random_case($sformatf("random_local_invalid_frag_drop[%0d]", i));
      env.gen.create_random_local_invalid_frag_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random local invalid frag drop %0d", i));
      end_random_case($sformatf("random_local_invalid_frag_drop[%0d]", i));

      begin_random_case($sformatf("random_local_payload_len_zero_drop[%0d]", i));
      env.gen.create_random_local_payload_len_zero_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random local payload len zero drop %0d", i));
      end_random_case($sformatf("random_local_payload_len_zero_drop[%0d]", i));

      begin_random_case($sformatf("random_remote_seq_zero_drop[%0d]", i));
      env.gen.create_random_remote_seq_zero_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random remote seq zero drop %0d", i));
      end_random_case($sformatf("random_remote_seq_zero_drop[%0d]", i));

      begin_random_case($sformatf("random_remote_frag_zero_drop[%0d]", i));
      env.gen.create_random_remote_frag_zero_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random remote frag zero drop %0d", i));
      end_random_case($sformatf("random_remote_frag_zero_drop[%0d]", i));

      begin_random_case($sformatf("random_remote_payload_len_zero_drop[%0d]", i));
      env.gen.create_random_remote_payload_len_zero_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random remote payload len zero drop %0d", i));
      end_random_case($sformatf("random_remote_payload_len_zero_drop[%0d]", i));

      begin_random_case($sformatf("random_local_reserved_low_drop[%0d]", i));
      env.gen.create_random_local_reserved_low_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random local reserved low drop %0d", i));
      end_random_case($sformatf("random_local_reserved_low_drop[%0d]", i));

      begin_random_case($sformatf("random_local_reserved_mid_drop[%0d]", i));
      env.gen.create_random_local_reserved_mid_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random local reserved mid drop %0d", i));
      end_random_case($sformatf("random_local_reserved_mid_drop[%0d]", i));

      begin_random_case($sformatf("random_local_reserved_high_drop[%0d]", i));
      env.gen.create_random_local_reserved_high_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random local reserved high drop %0d", i));
      end_random_case($sformatf("random_local_reserved_high_drop[%0d]", i));

      begin_random_case($sformatf("random_remote_reserved_low_drop[%0d]", i));
      env.gen.create_random_remote_reserved_low_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random remote reserved low drop %0d", i));
      end_random_case($sformatf("random_remote_reserved_low_drop[%0d]", i));

      begin_random_case($sformatf("random_remote_reserved_mid_drop[%0d]", i));
      env.gen.create_random_remote_reserved_mid_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random remote reserved mid drop %0d", i));
      end_random_case($sformatf("random_remote_reserved_mid_drop[%0d]", i));

      begin_random_case($sformatf("random_remote_reserved_high_drop[%0d]", i));
      env.gen.create_random_remote_reserved_high_drop_transaction(tr, i);
      run_drop_case(tr, $sformatf("random remote reserved high drop %0d", i));
      end_random_case($sformatf("random_remote_reserved_high_drop[%0d]", i));

    end

    random_case_report();
    final_report();

    $display("========================================");
    $display(" Finished %s", name);
    $display("========================================");

    $finish;
  endtask

endclass

`endif
