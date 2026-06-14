`timescale 1ns/1ps

`ifndef BIRD_BASE_TEST_SV
`define BIRD_BASE_TEST_SV

class bird_base_test;

  // Virtual interface
  virtual bird_if vif;

  // Testbench components
  bird_input_driver  input_drv;
  bird_local_monitor local_mon;
  bird_scoreboard    sb;

  string name;

  function new(
    virtual bird_if vif,
    string name = "bird_base_test"
  );
    this.vif  = vif;
    this.name = name;

    // Create testbench components
    input_drv = new(vif);
    local_mon = new(vif);
    sb        = new();
  endfunction

  task automatic apply_reset();
    begin
      $display("[%0t] %s: applying reset", $time, name);

      // Initialize all testbench-driven signals.
      vif.init_signals();

      // Keep local output not ready.
      // The local monitor will control local_rdy byte by byte.
      vif.local_rdy  = 1'b0;
      vif.remote_rdy = 1'b1;

      repeat (3) @(posedge vif.clk);

      // Release reset.
      vif.rst_n = 1'b1;

      $display("[%0t] %s: reset released", $time, name);

      // Wait a little before starting stimulus.
      repeat (2) @(posedge vif.clk);
    end
  endtask


  // Build expected local output
  function void build_expected_local_output(
    input  bird_transaction tr,
    output byte unsigned expected_q[$]
  );
    expected_q.delete();

    // Add payload bytes first.
    foreach (tr.payload[i]) begin
      expected_q.push_back(tr.payload[i]);
    end

    // Then add CRC bytes.
    expected_q.push_back(tr.crc_byte_1());
    expected_q.push_back(tr.crc_byte_2());
  endfunction

  task automatic run_local_smoke_test();
    bird_transaction tr;

    byte unsigned payload_q[$];
    byte unsigned expected_local_q[$];
    byte unsigned actual_local_q[$];

    begin
      $display("========================================");
      $display(" %s: local smoke test started", name);
      $display("========================================");

      // Create one valid local transaction.
      tr = new("local_smoke_transaction");

      payload_q.delete();
      payload_q.push_back(8'hAA);

      // Valid local packet:
      // payload_len = 1
      // frag_num    = 1
      // seq_num     = 1
      // CRC         = 16'h1234
      tr.set_valid_local(payload_q, 16'h1234);
      tr.print();

      // Send the transaction to the DUT.
      input_drv.send_transaction(tr);

      // Build expected local output from the transaction.
      build_expected_local_output(tr, expected_local_q);

      // Capture actual local output from the DUT.
      local_mon.capture_bytes(expected_local_q.size(), actual_local_q);

      // Compare expected and actual local output.
      sb.check_byte_queue("local_smoke_output",expected_local_q,actual_local_q);

      sb.check_drop_count(vif.drop_cnt, 16'd0);

      sb.check_no_remote_output(vif.remote_vld);

      $display("========================================");
      $display(" %s: local smoke test finished", name);
      $display("========================================");
    end
  endtask


  // ------------------------------------------------------------
  // Main run task

  task automatic run();
    begin
      $display("========================================");
      $display(" Starting %s", name);
      $display("========================================");

      apply_reset();

      run_local_smoke_test();

      repeat (5) @(posedge vif.clk);

      sb.report();

      $display("========================================");
      $display(" Finished %s", name);
      $display("========================================");
    end
  endtask

endclass

`endif
