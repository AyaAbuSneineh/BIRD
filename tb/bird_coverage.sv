`timescale 1ns/1ps
// ============================================================
// BIRD Functional Coverage - Student Edition Friendly
// ------------------------------------------------------------
// This class tracks which important scenarios were tested.
//
// It does not use SystemVerilog covergroup syntax.
// It uses normal counters so it works in Active-HDL Student Edition.
// ============================================================

`ifndef BIRD_COVERAGE_SV
`define BIRD_COVERAGE_SV

class bird_coverage;

  string name;

  // ------------------------------------------------------------
  // Traffic type coverage
  // ------------------------------------------------------------
  int local_count;
  int remote_count;

  // ------------------------------------------------------------
  // Payload length coverage
  // ------------------------------------------------------------
  int payload_len_zero_count;
  int payload_len_one_count;
  int payload_len_small_count;
  int payload_len_large_count;

  // ------------------------------------------------------------
  // Local cfg coverage
  // ------------------------------------------------------------
  int local_valid_cfg_count;
  int local_seq_zero_count;
  int local_invalid_frag_count;

  // ------------------------------------------------------------
  // Remote cfg coverage
  // ------------------------------------------------------------
  int remote_valid_cfg_count;
  int remote_seq_zero_count;
  int remote_frag_zero_count;

  // ------------------------------------------------------------
  // Error/drop coverage
  // ------------------------------------------------------------
  int reserved_bits_error_count;
  int drop_count_seen;

  // ------------------------------------------------------------
  // Backpressure coverage
  // ------------------------------------------------------------
  int local_backpressure_count;
  int remote_backpressure_count;

  // ------------------------------------------------------------
  // Reset coverage
  // ------------------------------------------------------------
  int reset_initial_count;
  int reset_after_drop_count;


  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  int remote_single_fragment_count;
  int remote_two_fragment_in_order_count;
  int remote_two_fragment_out_of_order_count;
  int remote_three_fragment_count;
  int remote_seq_mismatch_drop_count;
  int remote_new_packet_while_incomplete_drop_count;
  int reset_during_remote_accumulation_count;


  function new(string name = "bird_coverage");
    this.name = name;

    local_count               = 0;
    remote_count              = 0;

    payload_len_zero_count    = 0;
    payload_len_one_count     = 0;
    payload_len_small_count   = 0;
    payload_len_large_count   = 0;

    local_valid_cfg_count     = 0;
    local_seq_zero_count      = 0;
    local_invalid_frag_count  = 0;

    remote_valid_cfg_count    = 0;
    remote_seq_zero_count     = 0;
    remote_frag_zero_count    = 0;

    reserved_bits_error_count = 0;
    drop_count_seen           = 0;

    local_backpressure_count  = 0;
    remote_backpressure_count = 0;

    reset_initial_count       = 0;
    reset_after_drop_count    = 0;
    remote_single_fragment_count                  = 0;
    remote_two_fragment_in_order_count            = 0;
    remote_two_fragment_out_of_order_count        = 0;
    remote_three_fragment_count                   = 0;
    remote_seq_mismatch_drop_count                = 0;
    remote_new_packet_while_incomplete_drop_count = 0;
    reset_during_remote_accumulation_count        = 0;
  endfunction


  // ------------------------------------------------------------
  // Sample a transaction
  // ------------------------------------------------------------
  function void sample_transaction(bird_transaction tr);

    // Traffic type
    if (tr.traffic_type == 1'b0) begin	    
      local_count++;
    end 
	else begin
      remote_count++;
    end

    // Payload length bins
    if (tr.payload_len == 0) begin
      payload_len_zero_count++;
    end
    else if (tr.payload_len == 1) begin
      payload_len_one_count++;
    end
    else if (tr.payload_len <= 4) begin
      payload_len_small_count++;
    end
    else begin
      payload_len_large_count++;
    end

    // Reserved bits / cfg error
    if (tr.cfg_error_mask != 32'h0000_0000) begin
      reserved_bits_error_count++;
    end

    // Local cfg cases
    if (tr.traffic_type == 1'b0) begin
      if (tr.frag_num == 5'd1 && tr.seq_num != 5'd0 && tr.cfg_error_mask == 32'h0000_0000 && tr.payload_len != 0) begin
        local_valid_cfg_count++;
      end

      if (tr.seq_num == 5'd0) begin
        local_seq_zero_count++;
      end

      if (tr.frag_num != 5'd1) begin
        local_invalid_frag_count++;
      end
    end

    // Remote cfg cases
    else begin
      if (tr.frag_num != 5'd0 && tr.seq_num != 5'd0 && tr.cfg_error_mask == 32'h0000_0000 && tr.payload_len != 0) begin
        remote_valid_cfg_count++;
      end

      if (tr.seq_num == 5'd0) begin
        remote_seq_zero_count++;
      end

      if (tr.frag_num == 5'd0) begin
        remote_frag_zero_count++;
      end
    end

  endfunction


  // ------------------------------------------------------------
  // Sample drop counter
  // ------------------------------------------------------------
  function void sample_drop_seen(input logic [15:0] drop_cnt);
    if (drop_cnt != 16'd0) begin
      drop_count_seen++;
    end
  endfunction


  // ------------------------------------------------------------
  // Sample special scenarios
  // ------------------------------------------------------------
  function void sample_local_backpressure();
    local_backpressure_count++;
  endfunction

  function void sample_remote_backpressure();
    remote_backpressure_count++;
  endfunction

  function void sample_reset_initial();
    reset_initial_count++;
  endfunction

  function void sample_reset_after_drop();
    reset_after_drop_count++;
  endfunction


  // ------------------------------------------------------------
  // Print coverage report
  // ------------------------------------------------------------

  function void sample_remote_single_fragment();
    remote_single_fragment_count++;
  endfunction

  function void sample_remote_two_fragment_in_order();
    remote_two_fragment_in_order_count++;
  endfunction

  function void sample_remote_two_fragment_out_of_order();
    remote_two_fragment_out_of_order_count++;
  endfunction

  function void sample_remote_three_fragment();
    remote_three_fragment_count++;
  endfunction

  function void sample_remote_seq_mismatch_drop();
    remote_seq_mismatch_drop_count++;
  endfunction

  function void sample_remote_new_packet_while_incomplete_drop();
    remote_new_packet_while_incomplete_drop_count++;
  endfunction

  function void sample_reset_during_remote_accumulation();
    reset_during_remote_accumulation_count++;
  endfunction


  function void report();
    int covered_bins;
    int total_bins;

    covered_bins = 0;
    total_bins   = 24;

    if (local_count               > 0) covered_bins++;
    if (remote_count              > 0) covered_bins++;
    if (payload_len_zero_count    > 0) covered_bins++;
    if (payload_len_one_count     > 0) covered_bins++;
    if (payload_len_small_count   > 0) covered_bins++;
    if (payload_len_large_count   > 0) covered_bins++;
    if (local_valid_cfg_count     > 0) covered_bins++;
    if (local_seq_zero_count      > 0) covered_bins++;
    if (local_invalid_frag_count  > 0) covered_bins++;
    if (remote_valid_cfg_count    > 0) covered_bins++;
    if (remote_seq_zero_count     > 0) covered_bins++;
    if (remote_frag_zero_count    > 0) covered_bins++;
    if (reserved_bits_error_count > 0) covered_bins++;
    if (drop_count_seen           > 0) covered_bins++;
    if (local_backpressure_count  > 0) covered_bins++;
    if (remote_backpressure_count > 0) covered_bins++;
    if (reset_initial_count       > 0 || reset_after_drop_count > 0) covered_bins++;
    if (remote_single_fragment_count                  > 0) covered_bins++;
    if (remote_two_fragment_in_order_count            > 0) covered_bins++;
    if (remote_two_fragment_out_of_order_count        > 0) covered_bins++;
    if (remote_three_fragment_count                   > 0) covered_bins++;
    if (remote_seq_mismatch_drop_count                > 0) covered_bins++;
    if (remote_new_packet_while_incomplete_drop_count > 0) covered_bins++;
    if (reset_during_remote_accumulation_count        > 0) covered_bins++;


    $display("========================================");
    $display(" %s Functional Coverage Report", name);
    $display("========================================");

    $display("Traffic:");
    $display("  LOCAL transactions              : %0d", local_count);
    $display("  REMOTE transactions             : %0d", remote_count);

    $display("Payload length:");
    $display("  payload_len == 0                : %0d", payload_len_zero_count);
    $display("  payload_len == 1                : %0d", payload_len_one_count);
    $display("  payload_len 2..4                : %0d", payload_len_small_count);
    $display("  payload_len > 4                 : %0d", payload_len_large_count);

    $display("Local cfg:");
    $display("  valid local cfg                 : %0d", local_valid_cfg_count);
    $display("  local seq zero                  : %0d", local_seq_zero_count);
    $display("  invalid local frag              : %0d", local_invalid_frag_count);

    $display("Remote cfg:");
    $display("  valid remote cfg                : %0d", remote_valid_cfg_count);
    $display("  remote seq zero                 : %0d", remote_seq_zero_count);
    $display("  remote frag zero                : %0d", remote_frag_zero_count);

    $display("Errors:");
    $display("  reserved bits error             : %0d", reserved_bits_error_count);
    $display("  drop count observed             : %0d", drop_count_seen);

    $display("Backpressure:");
    $display("  local backpressure              : %0d", local_backpressure_count);
    $display("  remote backpressure             : %0d", remote_backpressure_count);

    $display("Reset:");
    $display("  reset initial                   : %0d", reset_initial_count);
    $display("  reset after drop                : %0d", reset_after_drop_count);
    $display("  reset during remote accumulation: %0d", reset_during_remote_accumulation_count);

    $display("Remote merge/order scenarios:");
    $display("  remote single fragment          : %0d", remote_single_fragment_count);
    $display("  remote two fragments in order   : %0d", remote_two_fragment_in_order_count);
    $display("  remote two fragments out order  : %0d", remote_two_fragment_out_of_order_count);
    $display("  remote three fragments          : %0d", remote_three_fragment_count);
    $display("  remote seq mismatch drop        : %0d", remote_seq_mismatch_drop_count);
    $display("  remote new pkt incomplete drop  : %0d", remote_new_packet_while_incomplete_drop_count);


    $display("----------------------------------------");
    $display("Covered bins: %0d / %0d", covered_bins, total_bins);
    $display("Coverage    : %0.2f%%", (covered_bins * 100.0) / total_bins);
    $display("========================================");
  endfunction

endclass

`endif
