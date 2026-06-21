`timescale 1ns/1ps
// ============================================================
// BIRD Environment
// ------------------------------------------------------------
// Simple directed-test environment:
//   generator -> gen2agt mailbox -> agent -> agt2drv mailbox -> driver
//   driver -> interface -> DUT
//   DUT -> interface -> monitors -> scoreboard/checks in tests
// ============================================================

`ifndef BIRD_ENVIRONMENT_SV
`define BIRD_ENVIRONMENT_SV

class bird_environment;

  string name;
  virtual bird_if vif;

  mailbox gen2agt_mbx;
  mailbox agt2drv_mbx;
  mailbox agt2sb_mbx;
  mailbox local_mon2sb_mbx;
  mailbox remote_mon2sb_mbx;
  
  bird_generator    gen;
  bird_agent        agt;
  bird_input_driver input_drv;
  bird_local_monitor local_mon;
  bird_remote_monitor remote_mon;
  bird_scoreboard   sb;
  bird_coverage     cov;

  function new(virtual bird_if vif, string name = "bird_environment");
    this.vif  = vif;
    this.name = name;

    gen2agt_mbx = new();
    agt2drv_mbx = new();
    agt2sb_mbx  = new();
    local_mon2sb_mbx  = new();
    remote_mon2sb_mbx = new();
    
    gen       = new(gen2agt_mbx);
    input_drv = new(vif);
    input_drv.set_mailbox(agt2drv_mbx);
    agt       = new(gen2agt_mbx, agt2drv_mbx, agt2sb_mbx);

    local_mon  = new(vif);
    remote_mon = new(vif);

    local_mon.set_mon2sb_mailbox(local_mon2sb_mbx);
    remote_mon.set_mon2sb_mailbox(remote_mon2sb_mbx);

    sb = new("bird_scoreboard", local_mon2sb_mbx, remote_mon2sb_mbx);
    cov        = new();
  endfunction

  task automatic send_transaction(input bird_transaction tr);
    begin
      if (tr == null) begin
        $error("[%0t] %s: null transaction was not sent", $time, name);
        return;
      end

      $display("[%0t] %s: sending '%s' through Generator/Agent/Driver flow",
               $time, name, tr.name);

      gen.send_transaction(tr);
      agt.run_one();
      input_drv.run_one();
    end
  endtask

  function void report();
    sb.report();
    cov.report();
  endfunction

endclass

`endif
