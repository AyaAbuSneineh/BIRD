BIRD_LOCAL_MONITOR_SV
`define BIRD_LOCAL_MONITOR_SV

class bird_local_monitor;

  virtual bird_if vif;
  string name;

  function new(
    virtual bird_if vif,
    string name = "bird_local_monitor"
  );
    this.vif  = vif;
    this.name = name;
  endfunction

  task automatic capture_byte(
    output byte unsigned actual_byte
  );
    begin
      @(negedge vif.clk);
      vif.local_rdy = 1'b0;

      while (vif.local_vld !== 1'b1) begin
        @(negedge vif.clk);
      end

      actual_byte = vif.data_local;

      $display("[%0t] %s: captured local byte %02h",
               $time, name, actual_byte);

      vif.local_rdy = 1'b1;
      @(posedge vif.clk);

      @(negedge vif.clk);
      vif.local_rdy = 1'b0;

      @(posedge vif.clk);
    end
  endtask

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
        actual_q.push_back(b);
      end

      $display("[%0t] %s: finished capturing local bytes",
               $time, name);
    end
  endtask

endclass

`endif
