interface bird_if(input logic clk);

  // Global signal
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

  // Clocking block for the input driver

  clocking input_drv_cb @(posedge clk);
    default input #1step output #0;

    output in_vld;
    output data_in;
    output cfg;

    input  in_rdy;
  endclocking

  // Clocking block for the input monitor
  clocking input_mon_cb @(posedge clk);
    default input #1step output #0;

    input in_vld;
    input in_rdy;
    input data_in;
    input cfg;
  endclocking

  // Clocking block for the local ready driver
 
  clocking local_drv_cb @(posedge clk);
    default input #1step output #0;

    output local_rdy;

    input  local_vld;
    input  data_local;
  endclocking


  // Clocking block for the local monitor
  
  clocking local_mon_cb @(posedge clk);
    default input #1step output #0;

    input local_vld;
    input local_rdy;
    input data_local;
  endclocking

  // Clocking block for the remote ready driver
  
  clocking remote_drv_cb @(posedge clk);
    default input #1step output #0;

    output remote_rdy;

    input  remote_vld;
    input  data_remote;
  endclocking


  // Clocking block for the remote monitor
  clocking remote_mon_cb @(posedge clk);
    default input #1step output #0;

    input remote_vld;
    input remote_rdy;
    input data_remote;
  endclocking

  // This is used to monitor drop_cnt changes

  clocking status_mon_cb @(posedge clk);
    default input #1step output #0;

    input drop_cnt;
  endclocking

  // We call this at the beginning of simulation before reset.

  task automatic init_signals();
    rst_n      = 1'b0;

    in_vld     = 1'b0;
    data_in    = 8'h00;
    cfg        = 32'h0000_0000;

    local_rdy  = 1'b1;
    remote_rdy = 1'b1;
  endtask

endinterface
