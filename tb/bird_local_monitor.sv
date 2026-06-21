`timescale 1ns/1ps
// ============================================================
// BIRD Local Monitor
// ------------------------------------------------------------
// This class captures bytes from the local output interface.
//
// It watches:
//   local_vld
//   local_rdy
//   data_local
//
// For now, this monitor also controls local_rdy byte by byte.
// The scoreboard will compare the captured bytes.
// ============================================================

`ifndef BIRD_LOCAL_MONITOR_SV
`define BIRD_LOCAL_MONITOR_SV

class bird_local_monitor;

  virtual bird_if vif;
  string name;
  int output_wait_timeout_cycles;
  bit last_capture_ok;
  mailbox mon2sb_mbx;


  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(
    virtual bird_if vif,
    string name = "bird_local_monitor"
  );
    this.vif  = vif;
    this.name = name;
    this.output_wait_timeout_cycles = 200;
    this.last_capture_ok = 1'b0;
    this.mon2sb_mbx = null;
  endfunction
  function void set_mon2sb_mailbox(mailbox mon2sb_mbx);
     this.mon2sb_mbx = mon2sb_mbx;
  endfunction

task automatic publish_local_bytes(input byte unsigned actual_q[$]);
  bird_output_item item;

  if (mon2sb_mbx == null) begin
    return;
  end

  item = new("local_bytes_actual");
  item.set_local_bytes(actual_q, vif.drop_cnt);

  mon2sb_mbx.put(item);

  $display("[%0t] %s: sent local bytes to scoreboard mailbox",
           $time, name);
endtask

task automatic publish_local_activity(input int activity_count);
  bird_output_item item;

  if (mon2sb_mbx == null) begin
    return;
  end

  item = new("local_activity_actual");
  item.set_local_activity(activity_count, vif.drop_cnt);

  mon2sb_mbx.put(item);

  $display("[%0t] %s: sent local activity count to scoreboard mailbox",
           $time, name);
endtask


  // ------------------------------------------------------------
  // Capture one local output byte
  // ------------------------------------------------------------
  // We keep local_rdy low while sampling, so the DUT cannot pop
  // the byte before we capture it.
  //
  // After capturing, we pulse local_rdy for one clock cycle to
  // consume exactly one byte.
  // ------------------------------------------------------------
  task automatic capture_byte(
    output byte unsigned actual_byte
  );
    begin
      actual_byte = 8'h00;
      last_capture_ok = 1'b0;

      // Do not consume while waiting.
      @(negedge vif.clk);
      vif.local_rdy = 1'b0;

      // Wait until the DUT presents valid local data. This wait is
      // bounded so an expected-pass test fails instead of hanging if the
      // DUT incorrectly drops the packet.
      for (int wait_cycle = 0; wait_cycle < output_wait_timeout_cycles; wait_cycle++) begin
        if (vif.local_vld === 1'b1) begin
          last_capture_ok = 1'b1;
          break;
        end
        @(negedge vif.clk);
      end

      if (!last_capture_ok) begin
        $error("[%0t] %s: timeout waiting for local_vld after %0d cycles",
               $time, name, output_wait_timeout_cycles);
        return;
      end

      // Capture stable data.
      actual_byte = vif.data_local;

      $display("[%0t] %s: captured local byte %02h",
               $time, name, actual_byte);

      // Consume exactly one byte.
      vif.local_rdy = 1'b1;
      @(posedge vif.clk);

      // Stop consuming.
      @(negedge vif.clk);
      vif.local_rdy = 1'b0;

      // Give the DUT one clock to present the next byte.
      @(posedge vif.clk);
    end
  endtask


  // ------------------------------------------------------------
  // Capture a fixed number of local output bytes
  // ------------------------------------------------------------
  task automatic capture_bytes(
    input  int           number_of_bytes,
    output byte unsigned actual_q[$]
  );
    byte unsigned b;

    begin
      actual_q.delete();

      $display("[%0t] %s: capturing %0d local bytes",
               $time, name, number_of_bytes);

      for (int i = 0; i < number_of_bytes; i++) begin
        capture_byte(b);
        if (!last_capture_ok) begin
          $error("[%0t] %s: missing local byte[%0d]", $time, name, i);
          break;
        end
        actual_q.push_back(b);
      end

      $display("[%0t] %s: finished capturing local bytes",
               $time, name);
      publish_local_bytes(actual_q);
    end
  endtask
  
    // ------------------------------------------------------------
  // Count local output activity for a number of cycles
  // ------------------------------------------------------------
  // This is used for drop tests.
  // If the packet is dropped, local_vld should not assert.
  // ------------------------------------------------------------
  task automatic count_local_activity(
    input  int cycles_to_watch,
    output int activity_count
  );
    begin
      activity_count = 0;

      // Keep local ready high here so if any unexpected data appears,
      // it can be transferred and counted.
      @(negedge vif.clk);
      vif.local_rdy = 1'b1;

      for (int i = 0; i < cycles_to_watch; i++) begin
        @(posedge vif.clk);

        if (vif.local_vld === 1'b1) begin   // impoosible to vld becuse dut do not have output
          activity_count++;
          $display("[%0t] %s: unexpected local activity detected, data = %02h",$time, name, vif.data_local);
        end
      end

      @(negedge vif.clk);
      vif.local_rdy = 1'b0;
      publish_local_activity(activity_count);
    end
  endtask
  
    // ------------------------------------------------------------
  // Check local output stability under backpressure
  // ------------------------------------------------------------

  task automatic check_stable_under_backpressure(input  int cycles_to_check, output bit stable_ok,output byte unsigned observed_byte);
    byte unsigned first_byte;

    begin
      stable_ok = 1'b1;
      observed_byte = 8'h00;

      // Keep local_rdy low to create backpressure.
      @(negedge vif.clk);
      vif.local_rdy = 1'b0;

      // Wait until DUT presents local output. Bound the wait so a
      // missing expected output is reported as a failure.
      last_capture_ok = 1'b0;
      for (int wait_cycle = 0; wait_cycle < output_wait_timeout_cycles; wait_cycle++) begin
        if (vif.local_vld === 1'b1) begin
          last_capture_ok = 1'b1;
          break;
        end
        @(negedge vif.clk);
      end

      if (!last_capture_ok) begin
        stable_ok = 1'b0;
        $error("[%0t] %s: timeout waiting for local_vld before backpressure check after %0d cycles",
               $time, name, output_wait_timeout_cycles);
        return;
      end

      // Capture the first stable value.
      first_byte    = vif.data_local;
      observed_byte = first_byte;

      $display("[%0t] %s: starting local backpressure check, first byte = %02h",$time, name, first_byte);

      // Keep local_rdy low and check that data_local does not change.
      for (int i = 0; i < cycles_to_check; i++) begin
        @(negedge vif.clk);

        if (vif.data_local !== first_byte) begin
          stable_ok = 1'b0;

          $display("[%0t] %s: local data changed under backpressure: expected %02h, got %02h",$time, name, first_byte, vif.data_local);
        end
      end

      $display("[%0t] %s: finished local backpressure check",$time, name);
    end
  endtask

endclass

`endif
