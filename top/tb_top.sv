// ============================================================
// BIRD Testbench Top
// ------------------------------------------------------------
// Step 11:
// tb_top is now clean.
// It only creates the clock, interface, DUT, and starts the test.
// ============================================================

`timescale 1ns/1ps

module tb_top;

  // ------------------------------------------------------------
  // Clock signal
  // ------------------------------------------------------------
  logic clk;

  // ------------------------------------------------------------
  // Create the interface
  // ------------------------------------------------------------
  bird_if vif(clk);

  // ------------------------------------------------------------
  // Instantiate the DUT
  // ------------------------------------------------------------
  bird dut (
    .clk         (clk),
    .rst_n       (vif.rst_n),

    // Input interface
    .in_vld      (vif.in_vld),
    .in_rdy      (vif.in_rdy),
    .data_in     (vif.data_in),
    .cfg         (vif.cfg),

    // Status output
    .drop_cnt    (vif.drop_cnt),

    // Local output interface
    .local_vld   (vif.local_vld),
    .local_rdy   (vif.local_rdy),
    .data_local  (vif.data_local),

    // Remote output interface
    .remote_vld  (vif.remote_vld),
    .remote_rdy  (vif.remote_rdy),
    .data_remote (vif.data_remote)
  );
// ------------------------------------------------------------
  // Clock generation
  // ------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end
  
    // ------------------------------------------------------------
  // Start the selected test
  // ------------------------------------------------------------
  initial begin
    string testname;
	//testname = "local_multi_byte_test";

    // Base class handle.
    // This lets tb_top run any test that extends bird_base_test.
    bird_base_test test;  

    // Specific test handles.
    local_basic_test      local_basic;
    local_multi_byte_test local_multi;
	local_seq_non1_valid_test local_seq_non1_valid;
	local_seq_max_valid_test local_seq_max_valid;
	local_seq_zero_drop_test local_seq_zero_drop;
	local_frag_zero_drop_test local_frag_zero_drop;
	local_invalid_frag_test local_invalid_frag ;
	reserved_bits_drop_test reserved_bits_test;
	reserved_mid_bits_drop_test reserved_mid_bits_test;
	reserved_high_bits_drop_test reserved_high_bits_test;
	payload_len_zero_drop_test payload_len_zero_test;  
	local_payload_len_large_valid_test local_payload_len_large_valid;
	drop_count_accumulation_test drop_count_accumulation;
	drop_count_hold_after_valid_test drop_count_hold_after_valid;
	local_remote_switching_test local_remote_switching;
	
	
	remote_single_fragment_test remote_single; 
	remote_seq_max_valid_test remote_seq_max_valid;
	remote_two_fragment_in_order_test remote_two_fragment_in_order;
	remote_two_fragment_out_of_order_test remote_two_fragment_out_of_order;
	remote_seq_mismatch_drop_test remote_seq_mismatch;
        remote_seq_mismatch_same_frag_drop_test remote_seq_mismatch_same_frag_drop;
	remote_new_packet_while_incomplete_drop_test remote_new_packet_while_incomplete;
	remote_multi_byte_test remote_multi; 
	remote_payload_len_large_valid_test remote_payload_len_large_valid;
	remote_drop_recovery_test remote_drop_recovery;
	remote_seq_zero_drop_test remote_seq_zero; 
	remote_frag_zero_drop_test remote_frag_zero;
	remote_payload_len_zero_drop_test remote_payload_len_zero;
	remote_reserved_bits_drop_test remote_reserved_bits;
	remote_reserved_mid_bits_drop_test remote_reserved_mid_bits;
	remote_reserved_high_bits_drop_test remote_reserved_high_bits;
	local_backpressure_test local_backpressure;
	remote_backpressure_test remote_backpressure;
	reset_initial_test reset_initial;
	reset_after_drop_test reset_after_drop;
	reset_during_remote_accumulation_test reset_during_remote_accumulation;
        
	remote_single_seq5_frag1_valid_test remote_single_seq5_frag1_valid;

	remote_three_fragment_in_order_test remote_three_fragment_in_order;
	remote_three_fragment_3_1_2_test remote_three_fragment_3_1_2;
        
        random_all_cases_test random_all_cases;
       
        remote_frag2_seq2_next remote_frag2_seq2_next_h;
        remote_frag3_seq4_next remote_frag3_seq4_next_h;
        remote_frag5_seq3_next remote_frag5_seq3_next_h;

	

    // ----------------------------------------------------------
    // Read test name from command line
    // ----------------------------------------------------------
    // If no +TESTNAME is provided, run local_basic_test.
    // ----------------------------------------------------------
    if (!$value$plusargs("TESTNAME=%s", testname)) begin
      testname = "reset_after_drop_test";
    end

    $display("========================================");
    $display(" tb_top selected test: %s", testname);
    $display("========================================");

    // ----------------------------------------------------------
    // Create the selected test
    // ----------------------------------------------------------
    if (testname == "local_basic_test") begin
      local_basic = new(vif);
      test = local_basic;
    end
    else if (testname == "local_multi_byte_test") begin
      local_multi = new(vif);
      test = local_multi;
    end
	else if (testname == "local_seq_non1_valid_test") begin
      local_seq_non1_valid = new(vif);
      test = local_seq_non1_valid;
    end
	else if (testname == "local_seq_max_valid_test") begin
      local_seq_max_valid = new(vif);
      test = local_seq_max_valid;
    end
	else if (testname == "local_seq_zero_drop_test") begin
      local_seq_zero_drop = new(vif);
      test = local_seq_zero_drop;
    end
	else if (testname == "local_frag_zero_drop_test") begin
      local_frag_zero_drop = new(vif);
      test = local_frag_zero_drop;
    end
	else if (testname == "local_invalid_frag_test") begin
		local_invalid_frag = new(vif);
		test = local_invalid_frag;
	end
	else if (testname == "reserved_bits_drop_test") begin
  		reserved_bits_test = new(vif);
  		test = reserved_bits_test;
	end
	else if (testname == "reserved_mid_bits_drop_test") begin
  		reserved_mid_bits_test = new(vif);
  		test = reserved_mid_bits_test;
	end
	else if (testname == "reserved_high_bits_drop_test") begin
  		reserved_high_bits_test = new(vif);
  		test = reserved_high_bits_test;
	end
	else if (testname == "payload_len_zero_drop_test") begin
  		payload_len_zero_test = new(vif);
  		test = payload_len_zero_test;
	end
	else if (testname == "local_payload_len_large_valid_test") begin
  		local_payload_len_large_valid = new(vif);
  		test = local_payload_len_large_valid;
	end
	else if (testname == "drop_count_accumulation_test") begin
  		drop_count_accumulation = new(vif);
  		test = drop_count_accumulation;
	end
	else if (testname == "drop_count_hold_after_valid_test") begin
  		drop_count_hold_after_valid = new(vif);
  		test = drop_count_hold_after_valid;
	end
	else if (testname == "local_remote_switching_test") begin
  		local_remote_switching = new(vif);
  		test = local_remote_switching;
	end
	else if (testname == "remote_single_fragment_test") begin
	  remote_single = new(vif);
	  test = remote_single;
	end
	else if (testname == "remote_seq_max_valid_test") begin
	  remote_seq_max_valid = new(vif);
	  test = remote_seq_max_valid;
	end
	else if (testname == "remote_two_fragment_in_order_test") begin
	  remote_two_fragment_in_order = new(vif);
	  test = remote_two_fragment_in_order;
	end
	else if (testname == "remote_two_fragment_out_of_order_test") begin
	  remote_two_fragment_out_of_order = new(vif);
	  test = remote_two_fragment_out_of_order;
	end
	else if (testname == "remote_seq_mismatch_same_frag_drop_test") begin
      remote_seq_mismatch_same_frag_drop = new(vif);
      test = remote_seq_mismatch_same_frag_drop;
    end
    else if (testname == "remote_seq_mismatch_drop_test") begin
	  remote_seq_mismatch = new(vif);
	  test = remote_seq_mismatch;
	end
	else if (testname == "remote_new_packet_while_incomplete_drop_test") begin
	  remote_new_packet_while_incomplete = new(vif);
	  test = remote_new_packet_while_incomplete;
	end
	else if (testname == "remote_multi_byte_test") begin
	  remote_multi = new(vif);
	  test = remote_multi;
	end
	else if (testname == "remote_payload_len_large_valid_test") begin
	  remote_payload_len_large_valid = new(vif);
	  test = remote_payload_len_large_valid;
	end
	else if (testname == "remote_drop_recovery_test") begin
	  remote_drop_recovery = new(vif);
	  test = remote_drop_recovery;
	end
	else if (testname == "remote_seq_zero_drop_test") begin
	  remote_seq_zero = new(vif);
	  test = remote_seq_zero;
	end
	else if (testname == "remote_frag_zero_drop_test") begin
	  remote_frag_zero = new(vif);
	  test = remote_frag_zero;
	end
	else if (testname == "remote_payload_len_zero_drop_test") begin
	  remote_payload_len_zero = new(vif);
	  test = remote_payload_len_zero;
	end
	else if (testname == "remote_reserved_bits_drop_test") begin
	  remote_reserved_bits = new(vif);
	  test = remote_reserved_bits;
	end
	else if (testname == "remote_reserved_mid_bits_drop_test") begin
	  remote_reserved_mid_bits = new(vif);
	  test = remote_reserved_mid_bits;
	end
	else if (testname == "remote_reserved_high_bits_drop_test") begin
	  remote_reserved_high_bits = new(vif);
	  test = remote_reserved_high_bits;
	end
	else if (testname == "local_backpressure_test") begin
	  local_backpressure = new(vif);
	  test = local_backpressure;
	end
	else if (testname == "remote_backpressure_test") begin
	  remote_backpressure = new(vif);
	  test = remote_backpressure;
	end
	else if (testname == "reset_initial_test") begin
	  reset_initial = new(vif);
	  test = reset_initial;
	end
	else if (testname == "reset_after_drop_test") begin
	  reset_after_drop = new(vif);
	  test = reset_after_drop;
	end
	else if (testname == "reset_during_remote_accumulation_test") begin
	  reset_during_remote_accumulation = new(vif);
	  test = reset_during_remote_accumulation;
	end
        else if (testname == "random_all_cases_test") begin
          random_all_cases = new(vif);
          test = random_all_cases;
        end
	else if (testname == "remote_single_fragment_test") begin
  	  remote_single = new(vif);
          test = remote_single;
	end
	else if (testname == "remote_single_seq5_frag1_valid_test") begin
  	  remote_single_seq5_frag1_valid = new(vif);
  	  test = remote_single_seq5_frag1_valid;
	end
	else if (testname == "remote_three_fragment_in_order_test") begin
  	  remote_three_fragment_in_order = new(vif);
  	  test = remote_three_fragment_in_order;
	end
	else if (testname == "remote_three_fragment_3_1_2_test") begin
  	  remote_three_fragment_3_1_2 = new(vif);
  	  test = remote_three_fragment_3_1_2;
	end
	 else if (testname == "remote_frag2_seq2_next") begin
          remote_frag2_seq2_next_h = new(vif);
          test = remote_frag2_seq2_next_h;
        end
        else if (testname == "remote_frag3_seq4_next") begin
          remote_frag3_seq4_next_h = new(vif);
          test = remote_frag3_seq4_next_h;
        end
        else if (testname == "remote_frag5_seq3_next") begin
          remote_frag5_seq3_next_h = new(vif);
          test = remote_frag5_seq3_next_h;
        end
           else begin
      $display("[%0t] ERROR: Unknown TESTNAME = %s", $time, testname);
      $display("[%0t] Running default local_basic_test instead", $time);

      local_basic = new(vif);
      test = local_basic;
    end

    // ----------------------------------------------------------
    // Run the selected test
    // ----------------------------------------------------------
    test.run();
	  // ------------------------------------------------------------
  // Assertions

    $finish;
  end

endmodule 

