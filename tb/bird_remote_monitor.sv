`timescale 1ns/1ps
// ============================================================
// BIRD Remote Monitor
// ------------------------------------------------------------
// This class captures words from the remote output interface.
//
// It watches:
//   remote_vld
//   remote_rdy
//   data_remote
//
// Remote output is 32-bit wide, unlike local output which is
// 8-bit wide.
// ============================================================

`ifndef BIRD_REMOTE_MONITOR_SV
`define BIRD_REMOTE_MONITOR_SV

class bird_remote_monitor;

  // Virtual interface handle
  virtual bird_if vif;

  // Monitor name for readable messages
  string name;
  int output_wait_timeout_cycles;
  bit last_capture_ok;
  mailbox mon2sb_mbx;


  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "bird_remote_monitor");
    this.vif  = vif;
    this.name = name;
    this.output_wait_timeout_cycles = 200;
    this.last_capture_ok = 1'b0;
    this.mon2sb_mbx = null;
  endfunction
function void set_mon2sb_mailbox(mailbox mon2sb_mbx);
    this.mon2sb_mbx = mon2sb_mbx;
  endfunction

task automatic publish_remote_words(input logic [31:0] actual_q[$]);
  bird_output_item item;

  if (mon2sb_mbx == null) begin
    return;
  end

  item = new("remote_words_actual");
  item.set_remote_words(actual_q, vif.drop_cnt);

  mon2sb_mbx.put(item);

  $display("[%0t] %s: sent remote words to scoreboard mailbox",
           $time, name);
endtask

task automatic publish_remote_activity(input int activity_count);
  bird_output_item item;

  if (mon2sb_mbx == null) begin
    return;
  end

  item = new("remote_activity_actual");
  item.set_remote_activity(activity_count, vif.drop_cnt);

  mon2sb_mbx.put(item);

  $display("[%0t] %s: sent remote activity count to scoreboard mailbox",
           $time, name);
endtask




  // ------------------------------------------------------------
  // Capture one remote output word
  // ------------------------------------------------------------
  // We keep remote_rdy low while checking/capturing so the DUT
  // cannot pop the word before we store it.
  //
  // Then we pulse remote_rdy for one clock cycle to consume
  // exactly one word.
  // ------------------------------------------------------------
  task automatic capture_word(output logic [31:0] actual_word);
    begin
      actual_word = 32'h0000_0000;
      last_capture_ok = 1'b0;

      // Do not consume while waiting.
      @(negedge vif.clk);
      vif.remote_rdy = 1'b0;

      // Wait until the DUT presents valid remote data. This wait is
      // bounded so an expected-pass test fails instead of hanging if the
      // DUT incorrectly drops or never produces the packet.
      for (int wait_cycle = 0; wait_cycle < output_wait_timeout_cycles; wait_cycle++) begin
        if (vif.remote_vld === 1'b1) begin
          last_capture_ok = 1'b1;
          break;
        end
        @(negedge vif.clk);
      end

      if (!last_capture_ok) begin
        $error("[%0t] %s: timeout waiting for remote_vld after %0d cycles",
               $time, name, output_wait_timeout_cycles);
        return;
      end

      // Capture stable data.
      actual_word = vif.data_remote;

      $display("[%0t] %s: captured remote word %08h",$time, name, actual_word);

      // Consume exactly one remote word.
      vif.remote_rdy = 1'b1;
      @(posedge vif.clk);

      // Stop consuming.
      @(negedge vif.clk);
      vif.remote_rdy = 1'b0;

      // Give the DUT one clock to present the next word.
      @(posedge vif.clk);
    end
  endtask


  // ------------------------------------------------------------
  // Capture a fixed number of remote output words
  // ------------------------------------------------------------
  task automatic capture_words(input  int number_of_words,output logic [31:0] actual_q[$]);
  
  	logic [31:0] w;

    begin
      actual_q.delete();

      $display("[%0t] %s: capturing %0d remote words",$time, name, number_of_words);

      for (int i = 0; i < number_of_words; i++) begin
        capture_word(w);
        if (!last_capture_ok) begin
          $error("[%0t] %s: missing remote word[%0d]", $time, name, i);
          break;
        end
        actual_q.push_back(w);
      end

      $display("[%0t] %s: finished capturing remote words",$time, name);
      publish_remote_words(actual_q);
    end
  endtask


  // ------------------------------------------------------------
  // Count remote output activity for a number of cycles
  // ------------------------------------------------------------
  // This will be useful for tests where we expect no remote output.
  // ------------------------------------------------------------
  task automatic count_remote_activity(input  int cycles_to_watch,output int activity_count);
  
  begin
      activity_count = 0;

      // Keep remote ready high so any unexpected output can move.
      @(negedge vif.clk);
      vif.remote_rdy = 1'b1;

      for (int i = 0; i < cycles_to_watch; i++) begin
        @(posedge vif.clk);

        if (vif.remote_vld === 1'b1) begin
          activity_count++;

          $display("[%0t] %s: unexpected remote activity detected, data = %08h",$time, name, vif.data_remote);
        end
      end

      @(negedge vif.clk);
      vif.remote_rdy = 1'b0;
      publish_remote_activity(activity_count);
    end
  endtask
  
    // ------------------------------------------------------------
  // Check remote output stability under backpressure
  // ------------------------------------------------------------
  // Backpressure means:
  //   remote_vld = 1
  //   remote_rdy = 0
  //
  // In this case, data_remote should remain stable.
  // This task does not consume the word. It only observes it.
  // ------------------------------------------------------------
  task automatic check_stable_under_backpressure(input  int cycles_to_check,output bit stable_ok,output logic [31:0] observed_word);
    logic [31:0] first_word;

    begin
      stable_ok = 1'b1;
      observed_word = 32'h0000_0000;

      // Keep remote_rdy low to create backpressure.
      @(negedge vif.clk);
      vif.remote_rdy = 1'b0;

      // Wait until DUT presents remote output. Bound the wait so a
      // missing expected output is reported as a failure.
      last_capture_ok = 1'b0;
      for (int wait_cycle = 0; wait_cycle < output_wait_timeout_cycles; wait_cycle++) begin
        if (vif.remote_vld === 1'b1) begin
          last_capture_ok = 1'b1;
          break;
        end
        @(negedge vif.clk);
      end

      if (!last_capture_ok) begin
        stable_ok = 1'b0;
        $error("[%0t] %s: timeout waiting for remote_vld before backpressure check after %0d cycles",
               $time, name, output_wait_timeout_cycles);
        return;
      end

      // Capture the first stable value.
      first_word    = vif.data_remote;
      observed_word = first_word;

      $display("[%0t] %s: starting remote backpressure check, first word = %08h",$time, name, first_word);

      // Keep remote_rdy low and check that data_remote does not change.
      for (int i = 0; i < cycles_to_check; i++) begin
        @(negedge vif.clk);

        if (vif.data_remote !== first_word) begin
          stable_ok = 1'b0;

          $display("[%0t] %s: remote data changed under backpressure: expected %08h, got %08h",$time, name, first_word, vif.data_remote);
        end
      end

      $display("[%0t] %s: finished remote backpressure check",$time, name);
    end
  endtask

endclass

`endif
