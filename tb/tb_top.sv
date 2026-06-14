`timescale 1ns/1ps

module tb_top;

  logic clk;

  bird_if vif(clk);

  bird dut (
    .clk         (clk),
    .rst_n       (vif.rst_n),
    .in_vld      (vif.in_vld),
    .in_rdy      (vif.in_rdy),
    .data_in     (vif.data_in),
    .cfg         (vif.cfg),
    .drop_cnt    (vif.drop_cnt),
    .local_vld   (vif.local_vld),
    .local_rdy   (vif.local_rdy),
    .data_local  (vif.data_local),
    .remote_vld  (vif.remote_vld),
    .remote_rdy  (vif.remote_rdy),
    .data_remote (vif.data_remote)
  );

  
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  
  initial begin
    bird_base_test test;

    test = new(vif);

    test.run();

    $finish;
  end

endmodule
