`timescale 1ns/1ps
// ============================================================
// BIRD Agent
// ------------------------------------------------------------
// Simple non-UVM agent.
// It receives transactions from the generator and forwards them
// to the driver through agt2drv mailbox.
// ============================================================

`ifndef BIRD_AGENT_SV
`define BIRD_AGENT_SV

class bird_agent;

  string  name;
  mailbox gen2agt_mbx;
  mailbox agt2drv_mbx;
  mailbox agt2sb_mbx;
  int     forwarded_count;

  function new(
    mailbox gen2agt_mbx,
    mailbox agt2drv_mbx,
    mailbox agt2sb_mbx = null,
    string  name = "bird_agent"
  );
    this.name            = name;
    this.gen2agt_mbx     = gen2agt_mbx;
    this.agt2drv_mbx     = agt2drv_mbx;
    this.agt2sb_mbx      = agt2sb_mbx;
    this.forwarded_count = 0;

    if (this.gen2agt_mbx == null) begin
      this.gen2agt_mbx = new();
    end

    if (this.agt2drv_mbx == null) begin
      this.agt2drv_mbx = new();
    end
  endfunction

  task automatic run_one();
    bird_transaction tr;

    begin
      gen2agt_mbx.get(tr);

      if (tr == null) begin
        $error("[%0t] %s: got null transaction from gen2agt mailbox", $time, name);
        return;
      end

      forwarded_count++;
      $display("[%0t] %s: forwarding transaction '%s' to driver",
               $time, name, tr.name);

      if (agt2sb_mbx != null) begin
        agt2sb_mbx.put(tr);
      end

      agt2drv_mbx.put(tr);
    end
  endtask

endclass

`endif
