`timescale 1ns/1ps
// ============================================================
// BIRD Interface
// ------------------------------------------------------------
// This interface groups all DUT signals in one place.
// Testbench components will use this interface to drive and
// monitor the BIRD DUT.
// ============================================================

interface bird_if(input logic clk);

  // ------------------------------------------------------------
  // Global signal
  // ------------------------------------------------------------
  logic rst_n;

  // ------------------------------------------------------------
  // Input interface: Producer -> BIRD
  // ------------------------------------------------------------
  logic        in_vld;
  logic        in_rdy;
  logic [7:0]  data_in;
  logic [31:0] cfg;

  // ------------------------------------------------------------
  // Status output
  // ------------------------------------------------------------
  logic [15:0] drop_cnt;

  // ------------------------------------------------------------
  // Local output interface
  // ------------------------------------------------------------
  logic        local_vld;
  logic        local_rdy;
  logic [7:0]  data_local;

  // ------------------------------------------------------------
  // Remote output interface
  // ------------------------------------------------------------
  logic        remote_vld;
  logic        remote_rdy;
  logic [31:0] data_remote;

  // We call this at the beginning of simulation before reset.
  // ============================================================
  task automatic init_signals();
    rst_n      = 1'b0;

    in_vld     = 1'b0;
    data_in    = 8'h00;
    cfg        = 32'h0000_0000;

    local_rdy  = 1'b1;
    remote_rdy = 1'b1;
  endtask

endinterface