`timescale 1ns/1ps
//BIRD_SCOREBOARD_SV
`ifndef BIRD_SCOREBOARD_SV
`define BIRD_SCOREBOARD_SV

class bird_scoreboard;

  int pass_count;
  int fail_count;

  string name;


  function new(string name = "bird_scoreboard");
    this.name       = name;
    this.pass_count = 0;
    this.fail_count = 0;
  endfunction


  function void record_pass(string msg);
    pass_count++;
    $display("[%0t] %s PASS: %s", $time, name, msg);
  endfunction

  function void record_fail(string msg);
    fail_count++;
    $error("[%0t] %s FAIL: %s", $time, name, msg);
  endfunction


  function void check_byte_queue(
    input string        check_name,
    input byte unsigned expected_q[$],
    input byte unsigned actual_q[$]
  );
    int min_size;
    string msg;

    $display("[%0t] %s: checking %s", $time, name, check_name);

    if (expected_q.size() != actual_q.size()) begin
      $sformat(msg,
               "%s size mismatch: expected %0d bytes, got %0d bytes",
               check_name, expected_q.size(), actual_q.size());
      record_fail(msg);
    end else begin
      $sformat(msg,
               "%s size matched: %0d bytes",
               check_name, expected_q.size());
      record_pass(msg);
    end

    min_size = (expected_q.size() < actual_q.size())
               ? expected_q.size()
               : actual_q.size();

    for (int i = 0; i < min_size; i++) begin
      if (actual_q[i] !== expected_q[i]) begin
        $sformat(msg,
                 "%s byte[%0d] mismatch: expected %02h, got %02h",
                 check_name, i, expected_q[i], actual_q[i]);
        record_fail(msg);
      end else begin
        $sformat(msg,
                 "%s byte[%0d] matched: %02h",
                 check_name, i, actual_q[i]);
        record_pass(msg);
      end
    end
  endfunction


  function void check_drop_count(
    input logic [15:0] actual_drop_cnt,
    input logic [15:0] expected_drop_cnt
  );
    string msg;

    if (actual_drop_cnt !== expected_drop_cnt) begin
      $sformat(msg,
               "drop_cnt mismatch: expected %0d, got %0d",
               expected_drop_cnt, actual_drop_cnt);
      record_fail(msg);
    end else begin
      $sformat(msg,
               "drop_cnt matched: %0d",
               actual_drop_cnt);
      record_pass(msg);
    end
  endfunction



  function void check_no_remote_output(
    input logic remote_vld
  );
    if (remote_vld === 1'b1) begin
      record_fail("remote_vld should not be active for this local packet");
    end else begin
      record_pass("remote_vld is not active");
    end
  endfunction

  function void report();
    $display("========================================");
    $display(" %s Final Report", name);
    $display(" Passed checks : %0d", pass_count);
    $display(" Failed checks : %0d", fail_count);

    if (fail_count == 0) begin
      $display(" TEST RESULT   : PASS");
    end else begin
      $display(" TEST RESULT   : FAIL");
    end

    $display("========================================");
  endfunction

endclass

`endif
