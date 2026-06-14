//BIRRD_INPUT_DRIVER_SV
`define BIRD_INPUT_DRIVER_SV

class bird_input_driver;

  virtual bird_if vif;

  string name;

  function new(
    virtual bird_if vif,
    string name = "bird_input_driver"
  );
    this.vif  = vif;
    this.name = name;
  endfunction

    task automatic drive_idle();
    begin
      @(negedge vif.clk);

      vif.in_vld  = 1'b0;
      vif.data_in = 8'h00;
      vif.cfg     = 32'h0000_0000;
    end
  endtask

  // A transfer happens when:
  //   in_vld == 1 && in_rdy == 1
  task automatic send_byte(
    input logic [7:0]  data_byte,
    input logic [31:0] packet_cfg
  );
    begin
      @(negedge vif.clk);

      vif.in_vld  = 1'b1;
      vif.data_in = data_byte;
      vif.cfg     = packet_cfg;

      do begin
        @(posedge vif.clk);
      end while (vif.in_rdy !== 1'b1);
    end
  endtask


  task automatic send_transaction(
    input bird_transaction tr
  );
    begin
      $display("[%0t] %s: sending transaction '%s'",
               $time, name, tr.name);

      foreach (tr.payload[i]) begin
        send_byte(tr.payload[i], tr.cfg);
      end

      send_byte(tr.crc_byte_1(), tr.cfg);
      send_byte(tr.crc_byte_2(), tr.cfg);

      drive_idle();

      $display("[%0t] %s: finished transaction '%s'",
               $time, name, tr.name);
    end
  endtask

endclass

`endif
