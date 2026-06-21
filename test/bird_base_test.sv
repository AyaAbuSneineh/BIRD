`timescale 1ns/1ps
// ============================================================
// BIRD Base Test
// ------------------------------------------------------------
// This class contains common test utilities used by all tests.
//
// It creates:
//   - input driver
//   - local monitor
//   - scoreboard
//
// It also provides:
//   - reset task
//   - expected local output builder
//
// Specific test scenarios should extend this class.
// ============================================================

`ifndef BIRD_BASE_TEST_SV
`define BIRD_BASE_TEST_SV

class bird_base_test;

  // ------------------------------------------------------------
  // Virtual interface
  // ------------------------------------------------------------
  virtual bird_if vif;

  // ------------------------------------------------------------
  // Common testbench components
  // ------------------------------------------------------------
  bird_environment    env;
  bird_input_driver   input_drv;
  bird_local_monitor  local_mon;
  bird_remote_monitor remote_mon;
  bird_scoreboard     sb;
  bird_coverage       cov;

  string name;


  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(virtual bird_if vif,string name = "bird_base_test");
    this.vif  = vif;
    this.name = name;

    // Create the environment and keep short aliases for old tests.
    env        = new(vif);
    input_drv  = env.input_drv;
    local_mon  = env.local_mon;
    remote_mon = env.remote_mon;
    sb         = env.sb;
    cov        = env.cov;
  endfunction


  // ------------------------------------------------------------
  // Apply reset
  // ------------------------------------------------------------
  task automatic apply_reset();
    begin
      $display("[%0t] %s: applying reset", $time, name);

      // Initialize all testbench-driven signals.
      vif.init_signals();

      // Keep local output not ready.
      // The local monitor will control local_rdy byte by byte.
      vif.local_rdy  = 1'b0;
      vif.remote_rdy = 1'b0;

      // Hold reset active for a few clock cycles.
      repeat (3) @(posedge vif.clk);

      // Release reset.
      vif.rst_n = 1'b1;

      $display("[%0t] %s: reset released", $time, name);

      // Give the DUT time to start normal operation.
      repeat (2) @(posedge vif.clk);
    end
  endtask


  // ------------------------------------------------------------
  // Build expected local output
  // ------------------------------------------------------------
  // For valid local traffic, the DUT should forward:
  //   payload bytes + CRC bytes unchanged
  // ------------------------------------------------------------
  function void build_expected_local_output(
    input  bird_transaction tr,
    output byte unsigned expected_q[$]
  );
    expected_q.delete();

    // Add payload bytes.
    foreach (tr.payload[i]) begin
      expected_q.push_back(tr.payload[i]);
    end

    // Add CRC bytes.
    expected_q.push_back(tr.crc_byte_1());
    expected_q.push_back(tr.crc_byte_2());
  endfunction


  // ------------------------------------------------------------
  // Send through the clean environment flow
  // ------------------------------------------------------------
  task automatic send_transaction(input bird_transaction tr);
    begin
      env.send_transaction(tr);
    end
  endtask


  // ------------------------------------------------------------
  // Base run task
  // ------------------------------------------------------------
  // Derived tests should override this task.
  // ------------------------------------------------------------
  virtual task automatic run();
    begin
      $display("[%0t] %s: base run task called", $time, name);
      $display("[%0t] %s: no specific scenario implemented here", $time, name);
    end
  endtask
  
    // ------------------------------------------------------------
  // CRC16 helper
  // ------------------------------------------------------------
  // The PDF specifies that remote traffic uses a regenerated CRC16,
  // but it does not define polynomial, seed, reflection, or byte order.
  // This helper uses the behavior observed in the provided DUT/demo:
  //   polynomial = 16'h1021
  //   init       = 16'hFFFF
  //
  // Treat this as an implementation-clarified assumption unless the
  // instructor provides a different CRC16 definition.
  //
  // Remote traffic uses regenerated CRC over the merged payload.
  // ------------------------------------------------------------
  function automatic logic [15:0] crc16_ccitt_bytes(input byte unsigned bytes[$]);
    logic [15:0] crc;

    crc = 16'hFFFF;

    foreach (bytes[i]) begin
      crc ^= {bytes[i], 8'h00};

      for (int b = 0; b < 8; b++) begin
        if (crc[15]) begin
          crc = (crc << 1) ^ 16'h1021;
        end 
	  else begin
          crc = (crc << 1);
        end
      end
    end

    return crc;
  endfunction


  // ------------------------------------------------------------
  // Pack bytes into 32-bit words
  // ------------------------------------------------------------
  // The PDF says the remote output is a 32-bit data stream, but it
  // does not define byte packing. The provided DUT/demo packs remote
  // payload bytes little-endian inside each 32-bit word:
  //
  //   word[7:0]   = byte0
  //   word[15:8]  = byte1
  //   word[23:16] = byte2
  //   word[31:24] = byte3
  // ------------------------------------------------------------
  function void pack_bytes_to_words(input  byte unsigned bytes[$],output logic [31:0] words_q[$]);
  
  	int i;

    words_q.delete();
    i = 0;

    while (i < bytes.size()) begin
      logic [31:0] w;

      w = 32'h0000_0000;

      for (int k = 0; k < 4; k++) begin
        if (i < bytes.size()) begin
          w[8*k +: 8] = bytes[i];
          i++;
        end
      end

      words_q.push_back(w);
    end
  endfunction


  // ------------------------------------------------------------
  // Build expected remote output
  // ------------------------------------------------------------
  // For remote traffic, expected output is:
  //   packed merged payload words
  //   then CRC word {16'h0000, crc16}
  //
  // The CRC word placement is also an implementation-clarified
  // assumption because the PDF only says MergedPayload + CRC16 on a
  // 32-bit remote interface.
  // ------------------------------------------------------------
  function void build_expected_remote_output(input  byte unsigned merged_payload_q[$],output logic [31:0]  expected_remote_q[$]);
    logic [15:0] crc;

    expected_remote_q.delete();

    // Pack merged payload bytes into 32-bit words.
    pack_bytes_to_words(merged_payload_q, expected_remote_q);

    // Generate CRC over merged payload.
    crc = crc16_ccitt_bytes(merged_payload_q);

    // Implementation-clarified assumption: CRC16 is placed in the low
    // 16 bits of the final 32-bit remote word.
    expected_remote_q.push_back({16'h0000, crc});
  endfunction
  
  task automatic final_report();
    begin
      sb.report();
      cov.report();
    end
  endtask
  

  task automatic watch_payload_crc_boundary(
    input int    expected_payload_len,
    input string check_name
  );
    int accepted_count;
    int rx_state_after_edge;
    bit fail_reported;

    accepted_count = 0;
    fail_reported  = 0;

    forever begin
      @(posedge vif.clk);
      #1ps;

      if (vif.rst_n && vif.in_vld && vif.in_rdy) begin
        accepted_count++;
        rx_state_after_edge = int'($root.tb_top.dut.rx_st);

        // RTL states:
        // RX_IDLE    = 0
        // RX_PAYLOAD = 1
        // RX_CRC     = 2

        // Before the last payload byte, DUT must not enter CRC.
        if ((accepted_count < expected_payload_len) &&
            (rx_state_after_edge == 2) &&
            (!fail_reported)) begin

          sb.record_fail(
            $sformatf(
              "%s: DUT entered CRC too early after payload byte %0d/%0d, data_in=%02h",
              check_name,
              accepted_count,
              expected_payload_len,
              vif.data_in
            )
          );

          fail_reported = 1;
        end

        // Immediately after the last payload byte, DUT should move to CRC.
        if ((accepted_count == expected_payload_len) &&
            (rx_state_after_edge != 2) &&
            (!fail_reported)) begin

          sb.record_fail(
            $sformatf(
              "%s: DUT did not enter CRC after final payload byte %0d/%0d, data_in=%02h, rx_st=%0d",
              check_name,
              accepted_count,
              expected_payload_len,
              vif.data_in,
              rx_state_after_edge
            )
          );

          fail_reported = 1;
        end

        // Stop after payload bytes + 2 CRC bytes are accepted.
        if (accepted_count >= expected_payload_len + 2) begin
          break;
        end
      end
    end

    if (!fail_reported) begin
      sb.record_pass(
        $sformatf(
          "%s: payload/CRC boundary is correct for payload_len=%0d",
          check_name,
          expected_payload_len
        )
      );
    end
  endtask


  task automatic send_transaction_with_crc_boundary_check(
    input bird_transaction tr,
    input string           check_name
  );
    int expected_payload_len;

    expected_payload_len = int'(tr.cfg[15:8]);

    fork
      watch_payload_crc_boundary(
        expected_payload_len,
        check_name
      );

      send_transaction(tr);
    join
  endtask

endclass

`endif
