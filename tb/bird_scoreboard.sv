`timescale 1ns/1ps
 // ============================================================
// BIRD Scoreboard
// ------------------------------------------------------------
// The scoreboard compares expected results with actual results.


`ifndef BIRD_SCOREBOARD_SV
`define BIRD_SCOREBOARD_SV

class bird_scoreboard;

  // ------------------------------------------------------------
  // Counters for final report
  // ------------------------------------------------------------
  int pass_count;
  int fail_count;

  string name;

  mailbox local_mon2sb_mbx;
  mailbox remote_mon2sb_mbx;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(string name = "bird_scoreboard",mailbox local_mon2sb_mbx = null,mailbox remote_mon2sb_mbx = null);
    this.name       = name;
    this.pass_count = 0;
    this.fail_count = 0;

    this.local_mon2sb_mbx  = local_mon2sb_mbx;
    this.remote_mon2sb_mbx = remote_mon2sb_mbx;
  endfunction


  function void set_monitor_mailboxes(
  mailbox local_mon2sb_mbx,
  mailbox remote_mon2sb_mbx
  );
    this.local_mon2sb_mbx  = local_mon2sb_mbx;
    this.remote_mon2sb_mbx = remote_mon2sb_mbx;
  endfunction


  // ------------------------------------------------------------
  // Internal helper: record pass
  // ------------------------------------------------------------
  function void record_pass(string msg);
    pass_count++;
    $display("[%0t] %s PASS: %s", $time, name, msg);
  endfunction


  // ------------------------------------------------------------
  // Internal helper: record fail
  // ------------------------------------------------------------
  function void record_fail(string msg);
    fail_count++;
    $error("[%0t] %s FAIL: %s", $time, name, msg);
  endfunction


  // ------------------------------------------------------------
  // Compare expected local bytes with actual local bytes
  // ------------------------------------------------------------
  function void check_byte_queue(
    input string        check_name,
    input byte unsigned expected_q[$],
    input byte unsigned actual_q[$]
  );
    int min_size;
    string msg;

    $display("[%0t] %s: checking %s", $time, name, check_name);

    // First check the size.
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

    // Compare only the common number of bytes, so the loop is safe.
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


  // ------------------------------------------------------------
  // Check drop counter
  // ------------------------------------------------------------
  function void check_drop_count(input logic [15:0] actual_drop_cnt,input logic [15:0] expected_drop_cnt);
    string msg;

    if (actual_drop_cnt !== expected_drop_cnt) begin  
		
      $sformat(msg,"drop_cnt mismatch: expected %0d, got %0d",expected_drop_cnt, actual_drop_cnt);
      record_fail(msg);
    
	end 

	else begin
      $sformat(msg,"drop_cnt matched: %0d",actual_drop_cnt);
      record_pass(msg);
    end
	
  endfunction


  // ------------------------------------------------------------
  // Check that remote output is not active
  // ------------------------------------------------------------
  function void check_no_remote_output(input logic remote_vld);
    if (remote_vld === 1'b1) begin
      record_fail("remote_vld should not be active for this local packet");
    end 
	
	else begin
      record_pass("remote_vld is not active");
    end
  endfunction


  // ------------------------------------------------------------
  // Final report
  // ------------------------------------------------------------
  function void report();
    $display("========================================");
    $display(" %s Final Report", name);
    $display(" Passed checks : %0d", pass_count);
    $display(" Failed checks : %0d", fail_count);

    if (fail_count == 0) begin
      $display(" TEST RESULT   : PASS");
    end 
	
	else begin
      $display(" TEST RESULT   : FAIL");
    end

    $display("========================================");
  endfunction

  function void check_no_local_activity(input int activity_count);
    string msg;

    if (activity_count != 0) begin
      $sformat(msg,"local output should be inactive, but activity_count = %0d",activity_count);
      record_fail(msg);
    end 
	
	else begin
      record_pass("no local output activity detected");
    end
endfunction


  // ------------------------------------------------------------
  // Compare expected remote words with actual remote words
  // ------------------------------------------------------------
  function void check_word_queue(input string check_name, input logic [31:0] expected_q[$], input logic [31:0] actual_q[$]);
  
  	int min_size;
    string msg;

    $display("[%0t] %s: checking %s", $time, name, check_name);

    // First check the queue size.
    if (expected_q.size() != actual_q.size()) begin
      $sformat(msg,"%s size mismatch: expected %0d words, got %0d words",check_name, expected_q.size(), actual_q.size());
      record_fail(msg);
    end 
	else begin
      $sformat(msg,"%s size matched: %0d words",check_name, expected_q.size());
      record_pass(msg);
    end

    // Compare only common words to avoid out-of-bound access.
    min_size = (expected_q.size() < actual_q.size())? expected_q.size(): actual_q.size();

    for (int i = 0; i < min_size; i++) begin
      if (actual_q[i] !== expected_q[i]) begin
        $sformat(msg,"%s word[%0d] mismatch: expected %08h, got %08h", check_name, i, expected_q[i], actual_q[i]);
        record_fail(msg);
      end 
	  else begin
        $sformat(msg,"%s word[%0d] matched: %08h",check_name, i, actual_q[i]);
        record_pass(msg);
      end
    end
  endfunction


  // ------------------------------------------------------------
  // Check that no remote output activity happened
  // ------------------------------------------------------------
  function void check_no_remote_activity(input int activity_count);
    string msg;

    if (activity_count != 0) begin
      $sformat(msg,"remote output should be inactive, but activity_count = %0d",activity_count);
      record_fail(msg);
    end 
	else begin
      record_pass("no remote output activity detected");
    end
  endfunction

  // ------------------------------------------------------------
  // Check local output stability result
  // ------------------------------------------------------------
  function void check_local_backpressure_stability(input bit stable_ok,input byte unsigned observed_byte,input byte unsigned expected_byte);
    string msg;

    if (!stable_ok) begin
      record_fail("data_local changed while local_rdy was low");
    end else begin
      record_pass("data_local stayed stable while local_rdy was low");
    end

    if (observed_byte !== expected_byte) begin
      $sformat(msg,"first local byte under backpressure mismatch: expected %02h, got %02h",expected_byte, observed_byte);
      record_fail(msg);
    end else begin
      $sformat(msg,"first local byte under backpressure matched: %02h",observed_byte);
      record_pass(msg);
    end
  endfunction

    // ------------------------------------------------------------
  // Check remote output stability result
  // ------------------------------------------------------------
  function void check_remote_backpressure_stability(
    input bit          stable_ok,
    input logic [31:0] observed_word,
    input logic [31:0] expected_word
  );
    string msg;

    if (!stable_ok) begin
      record_fail("data_remote changed while remote_rdy was low");
    end else begin
      record_pass("data_remote stayed stable while remote_rdy was low");
    end

    if (observed_word !== expected_word) begin
      $sformat(msg,
               "first remote word under backpressure mismatch: expected %08h, got %08h",
               expected_word, observed_word);
      record_fail(msg);
    end else begin
      $sformat(msg,
               "first remote word under backpressure matched: %08h",
               observed_word);
      record_pass(msg);
    end
  endfunction  

  // ------------------------------------------------------------
  // Check reset output state
  // ------------------------------------------------------------
  // During reset, the PDF specification requires:
  //   local_vld  should be 0
  //   remote_vld should be 0
  //   drop_cnt   should be 0
  //
  // The data outputs are not checked here because they are invalid
  // when local_vld/remote_vld are low.
  // ------------------------------------------------------------
  function void check_reset_outputs(
    input logic        local_vld,
    input logic [7:0]  data_local,
    input logic        remote_vld,
    input logic [31:0] data_remote,
    input logic [15:0] drop_cnt
  );
    string msg;

    if (local_vld !== 1'b0) begin
      record_fail("local_vld should be 0 during reset");
    end 
	else begin
      record_pass("local_vld is 0 during reset");
    end

    if (remote_vld !== 1'b0) begin
      record_fail("remote_vld should be 0 during reset");
    end else begin
      record_pass("remote_vld is 0 during reset");
    end

    if (drop_cnt !== 16'd0) begin
      $sformat(msg,
               "drop_cnt should be 0 during reset, got %0d",
               drop_cnt);
      record_fail(msg);
    end else begin
      record_pass("drop_cnt is 0 during reset");
    end
  endfunction




  task automatic get_next_local_item(output bird_output_item item);
  item = null;

  if (local_mon2sb_mbx == null) begin
    record_fail("local monitor to scoreboard mailbox is null");
    return;
  end

  local_mon2sb_mbx.get(item);

  if (item == null) begin
    record_fail("scoreboard received null local item");
  end
endtask


task automatic get_next_remote_item(output bird_output_item item);
  item = null;

  if (remote_mon2sb_mbx == null) begin
    record_fail("remote monitor to scoreboard mailbox is null");
    return;
  end

  remote_mon2sb_mbx.get(item);

  if (item == null) begin
    record_fail("scoreboard received null remote item");
  end
endtask


task automatic check_next_local_bytes(
  input string check_name,
  input byte unsigned expected_q[$]
);
  bird_output_item item;

  get_next_local_item(item);

  if (item == null) begin
    return;
  end

  if (item.kind != BIRD_OUT_LOCAL_BYTES) begin
    record_fail("expected local bytes item, but received different local item type");
    return;
  end

  check_byte_queue(check_name, expected_q, item.local_q);
endtask


task automatic check_next_remote_words(
  input string check_name,
  input logic [31:0] expected_q[$]
);
  bird_output_item item;

  get_next_remote_item(item);

  if (item == null) begin
    return;
  end

  if (item.kind != BIRD_OUT_REMOTE_WORDS) begin
    record_fail("expected remote words item, but received different remote item type");
    return;
  end

  check_word_queue(check_name, expected_q, item.remote_q);
endtask


task automatic check_next_no_local_activity(
  input string check_name = "no local output activity"
);
  bird_output_item item;

  get_next_local_item(item);

  if (item == null) begin
    return;
  end

  if (item.kind != BIRD_OUT_LOCAL_ACTIVITY) begin
    record_fail("expected local activity item, but received different local item type");
    return;
  end

  check_no_local_activity(item.activity_count);
endtask


task automatic check_next_no_remote_activity(
  input string check_name = "no remote output activity"
);
  bird_output_item item;

  get_next_remote_item(item);

  if (item == null) begin
    return;
  end

  if (item.kind != BIRD_OUT_REMOTE_ACTIVITY) begin
    record_fail("expected remote activity item, but received different remote item type");
    return;
  end

  check_no_remote_activity(item.activity_count);
endtask

endclass

`endif
