`timescale 1ns/1ps
										 // ============================================================
// BIRD Input Driver
// ------------------------------------------------------------
// This driver takes a bird_transaction and drives it into the
// DUT input interface.
//
// It drives:
//   in_vld
//   data_in
//   cfg
//
// It waits for:
//   in_rdy
//
// A BIRD input fragment is sent as:
//   payload bytes
//   then CRC byte 1
//   then CRC byte 2
// ============================================================

`ifndef BIRD_INPUT_DRIVER_SV
`define BIRD_INPUT_DRIVER_SV

class bird_input_driver;

  // ------------------------------------------------------------
  // Optional mailbox from the agent
  // ------------------------------------------------------------
  mailbox agt2drv_mbx;

  // ------------------------------------------------------------
  // Virtual interface handle
  // ------------------------------------------------------------
  // The driver does not create signals by itself.
  // It receives a handle to the interface created in tb_top.
  // ------------------------------------------------------------
  virtual bird_if vif;

  // Driver name for readable messages
  string name;
  int input_wait_timeout_cycles;
  bit last_send_ok;


  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(
    virtual bird_if vif,
    string name = "bird_input_driver"
  );
    this.vif  = vif;
    this.name = name;
    this.input_wait_timeout_cycles = 200;
    this.last_send_ok = 1'b0;
    this.agt2drv_mbx = null;
  endfunction


  // ------------------------------------------------------------
  // Drive input bus to idle
  // ------------------------------------------------------------
  // Important:
  // After the last byte, in_vld must go low so no extra input
  // transfer can occur after the intended fragment.
  // ------------------------------------------------------------
  task automatic drive_idle();
    begin
      @(negedge vif.clk);

      vif.in_vld  = 1'b0;
      vif.data_in = 8'h00;
      vif.cfg     = 32'h0000_0000;
    end
  endtask


  // ------------------------------------------------------------
  // Send one byte using valid/ready handshake
  // ------------------------------------------------------------
  // We drive on negedge so data is stable before the DUT samples
  // it on the next posedge.
  //
  // A transfer happens when:
  //   in_vld == 1 && in_rdy == 1
  // ------------------------------------------------------------
  task automatic send_byte(
    input logic [7:0]  data_byte,
    input logic [31:0] packet_cfg
  );
    begin
      last_send_ok = 1'b0;

      @(negedge vif.clk);

      vif.in_vld  = 1'b1;
      vif.data_in = data_byte;
      vif.cfg     = packet_cfg;

      // Wait until the DUT accepts the byte.
      // Wait in a handshake-safe way. A spec-compliant DUT is
      // allowed to deassert in_rdy, but the testbench must not hang
      // forever if the DUT never accepts the byte.
      for (int wait_cycle = 0; wait_cycle < input_wait_timeout_cycles; wait_cycle++) begin
        @(posedge vif.clk);
        if (vif.in_rdy === 1'b1) begin
          last_send_ok = 1'b1;
          break;
        end
      end

      if (!last_send_ok) begin
        $error("[%0t] %s: timeout waiting for in_rdy after %0d cycles while sending data=%02h cfg=%08h",
               $time, name, input_wait_timeout_cycles, data_byte, packet_cfg);
        drive_idle();
        return;
      end
    end
  endtask


  // ------------------------------------------------------------
  // Send a full transaction
  // ------------------------------------------------------------
  // The transaction contains:
  //   payload queue
  //   cfg
  //   input CRC
  //
  // The driver sends:
  //   all payload bytes
  //   CRC high byte
  //   CRC low byte
  // ------------------------------------------------------------
  task automatic send_transaction(
    input bird_transaction tr
  );
    begin
      $display("[%0t] %s: sending transaction '%s'",
               $time, name, tr.name);

      // Send payload bytes
      foreach (tr.payload[i]) begin
        send_byte(tr.payload[i], tr.cfg);
        if (!last_send_ok) begin
          $error("[%0t] %s: stopping transaction '%s' after payload byte[%0d] was not accepted",
                 $time, name, tr.name, i);
          return;
        end
      end

      // Send CRC bytes after payload
      send_byte(tr.crc_byte_1(), tr.cfg);
      if (!last_send_ok) begin
        $error("[%0t] %s: stopping transaction '%s' after CRC byte 1 was not accepted",
               $time, name, tr.name);
        return;
      end

      send_byte(tr.crc_byte_2(), tr.cfg);
      if (!last_send_ok) begin
        $error("[%0t] %s: stopping transaction '%s' after CRC byte 2 was not accepted",
               $time, name, tr.name);
        return;
      end

      // Return input bus to idle
      drive_idle();

      $display("[%0t] %s: finished transaction '%s'",
               $time, name, tr.name);
    end
  endtask


  // ------------------------------------------------------------
  // Connect driver to agent mailbox
  // ------------------------------------------------------------
  function void set_mailbox(mailbox agt2drv_mbx);
    this.agt2drv_mbx = agt2drv_mbx;
  endfunction


  // ------------------------------------------------------------
  // Get one transaction from agt2drv mailbox and drive it
  // ------------------------------------------------------------
  task automatic run_one();
    bird_transaction tr;

    begin
      if (agt2drv_mbx == null) begin
        $error("[%0t] %s: agt2drv mailbox is not connected", $time, name);
        return;
      end

      agt2drv_mbx.get(tr);

      if (tr == null) begin
        $error("[%0t] %s: got null transaction from agt2drv mailbox", $time, name);
        return;
      end

      $display("[%0t] %s: got transaction '%s' from agt2drv mailbox",
               $time, name, tr.name);
      send_transaction(tr);
    end
  endtask


endclass

`endif
