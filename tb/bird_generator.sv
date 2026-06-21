`timescale 1ns/1ps
// ============================================================
// BIRD Generator
// ------------------------------------------------------------
// Creates/sends transactions to the agent through gen2agt mailbox.
// Random tasks below use one-variable-at-a-time constraints.
// ============================================================

`ifndef BIRD_GENERATOR_SV
`define BIRD_GENERATOR_SV

class bird_generator;

  string  name;
  mailbox gen2agt_mbx;
  int     generated_count;

  function new(mailbox gen2agt_mbx, string name = "bird_generator");
    this.name            = name;
    this.gen2agt_mbx     = gen2agt_mbx;
    this.generated_count = 0;

    if (this.gen2agt_mbx == null) begin
      this.gen2agt_mbx = new();
    end
  endfunction

  task automatic send_transaction(input bird_transaction tr);
    begin
      if (tr == null) begin
        $error("[%0t] %s: null transaction was not sent", $time, name);
        return;
      end

      generated_count++;
      $display("[%0t] %s: put transaction '%s' into gen2agt mailbox",
               $time, name, tr.name);
      gen2agt_mbx.put(tr);
    end
  endtask

  // Kept for old random_valid_mixed_test compatibility.
  task automatic create_random_valid_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("random_valid_transaction_%0d", idx));

    if (!rand_tr.randomize() with {
          r_frag_num == 5'd1;
        }) begin
      $fatal(1, "[%0t] bird_generator: randomize failed for transaction %0d", $time, idx);
    end

    tr = rand_tr;

    $display("[%0t] bird_generator: created random valid transaction %0d", $time, idx);
    tr.print();
  endtask

  task automatic send_random_valid_transaction(output bird_transaction tr, input int unsigned idx);
    create_random_valid_transaction(tr, idx);
    send_transaction(tr);
  endtask

  // ============================================================
  // Valid local random cases
  // ============================================================

  task automatic create_random_local_payload_data_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_local_payload_data_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b0;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd4;
          r_payload.size() == 4;
        }) begin
      $fatal(1, "[%0t] generator: random local payload data failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_local_seq_num_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_local_seq_num_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b0;
          r_frag_num     == 5'd1;
          r_seq_num      inside {[1:31]};
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
          foreach (r_payload[i]) r_payload[i] == 8'hA5;
        }) begin
      $fatal(1, "[%0t] generator: random local seq num failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_local_payload_len_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_local_payload_len_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b0;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  inside {[1:32]};
          r_payload.size() == r_payload_len;
          foreach (r_payload[i]) r_payload[i] == 8'h5A;
        }) begin
      $fatal(1, "[%0t] generator: random local payload len failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  // ============================================================
  // Valid remote single-fragment random cases
  // ============================================================

  task automatic create_random_remote_payload_data_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_remote_payload_data_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b1;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
        }) begin
      $fatal(1, "[%0t] generator: random remote payload data failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_remote_seq_num_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_remote_seq_num_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b1;
          r_frag_num     == 5'd1;
          r_seq_num      inside {[1:31]};
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
          foreach (r_payload[i]) r_payload[i] == 8'hA5;
        }) begin
      $fatal(1, "[%0t] generator: random remote seq num failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_remote_payload_len_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_remote_payload_len_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b1;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  inside {[1:255]};
          r_payload.size() == r_payload_len;
          foreach (r_payload[i]) r_payload[i] == 8'h5A;
        }) begin
      $fatal(1, "[%0t] generator: random remote payload len failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  // ============================================================
  // Local drop cases
  // ============================================================

  task automatic create_random_local_seq_zero_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_local_seq_zero_%0d", idx));
    rand_tr.valid_random_packet_c.constraint_mode(0);

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b0;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd0;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
        }) begin
      $fatal(1, "[%0t] generator: random local seq zero failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_local_frag_zero_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_local_frag_zero_%0d", idx));
    rand_tr.valid_random_packet_c.constraint_mode(0);

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b0;
          r_frag_num     == 5'd0;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
        }) begin
      $fatal(1, "[%0t] generator: random local frag zero failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_local_invalid_frag_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_local_invalid_frag_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b0;
          r_frag_num     inside {[2:31]};
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
          foreach (r_payload[i]) r_payload[i] == 8'h3C;
        }) begin
      $fatal(1, "[%0t] generator: random local invalid frag failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_local_payload_len_zero_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_local_payload_zero_%0d", idx));
    rand_tr.valid_random_packet_c.constraint_mode(0);
    rand_tr.payload_len_dist_c.constraint_mode(0);

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b0;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd0;
          r_payload.size() == 1;
        }) begin
      $fatal(1, "[%0t] generator: random local payload zero failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  // ============================================================
  // Remote drop cases
  // ============================================================

  task automatic create_random_remote_seq_zero_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_remote_seq_zero_%0d", idx));
    rand_tr.valid_random_packet_c.constraint_mode(0);

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b1;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd0;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
        }) begin
      $fatal(1, "[%0t] generator: random remote seq zero failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_remote_frag_zero_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_remote_frag_zero_%0d", idx));
    rand_tr.valid_random_packet_c.constraint_mode(0);

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b1;
          r_frag_num     == 5'd0;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
        }) begin
      $fatal(1, "[%0t] generator: random remote frag zero failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_remote_payload_len_zero_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_remote_payload_zero_%0d", idx));
    rand_tr.valid_random_packet_c.constraint_mode(0);
    rand_tr.payload_len_dist_c.constraint_mode(0);

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b1;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd0;
          r_payload.size() == 1;
        }) begin
      $fatal(1, "[%0t] generator: random remote payload zero failed", $time);
    end

    tr = rand_tr;
    tr.print();
  endtask

  // ============================================================
  // Reserved bits drop cases
  // ============================================================

  task automatic create_random_local_reserved_low_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_local_reserved_low_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b0;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
          foreach (r_payload[i]) r_payload[i] == 8'h11;
        }) begin
      $fatal(1, "[%0t] generator: random local reserved low failed", $time);
    end

    rand_tr.add_cfg_error_mask(32'h0000_0001 << $urandom_range(1, 7));

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_local_reserved_mid_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_local_reserved_mid_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b0;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
          foreach (r_payload[i]) r_payload[i] == 8'h22;
        }) begin
      $fatal(1, "[%0t] generator: random local reserved mid failed", $time);
    end

    rand_tr.add_cfg_error_mask(32'h0000_0001 << $urandom_range(21, 23));

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_local_reserved_high_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_local_reserved_high_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b0;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
          foreach (r_payload[i]) r_payload[i] == 8'h33;
        }) begin
      $fatal(1, "[%0t] generator: random local reserved high failed", $time);
    end

    rand_tr.add_cfg_error_mask(32'h0000_0001 << $urandom_range(29, 31));

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_remote_reserved_low_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_remote_reserved_low_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b1;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
          foreach (r_payload[i]) r_payload[i] == 8'h44;
        }) begin
      $fatal(1, "[%0t] generator: random remote reserved low failed", $time);
    end

    rand_tr.add_cfg_error_mask(32'h0000_0001 << $urandom_range(1, 7));

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_remote_reserved_mid_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_remote_reserved_mid_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b1;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
          foreach (r_payload[i]) r_payload[i] == 8'h55;
        }) begin
      $fatal(1, "[%0t] generator: random remote reserved mid failed", $time);
    end

    rand_tr.add_cfg_error_mask(32'h0000_0001 << $urandom_range(21, 23));

    tr = rand_tr;
    tr.print();
  endtask

  task automatic create_random_remote_reserved_high_drop_transaction(output bird_transaction tr, input int unsigned idx);
    bird_random_transaction rand_tr;

    rand_tr = new($sformatf("rand_remote_reserved_high_%0d", idx));

    if (!rand_tr.randomize() with {
          r_traffic_type == 1'b1;
          r_frag_num     == 5'd1;
          r_seq_num      == 5'd1;
          r_payload_len  == 8'd1;
          r_payload.size() == 1;
          foreach (r_payload[i]) r_payload[i] == 8'h66;
        }) begin
      $fatal(1, "[%0t] generator: random remote reserved high failed", $time);
    end

    rand_tr.add_cfg_error_mask(32'h0000_0001 << $urandom_range(29, 31));

    tr = rand_tr;
    tr.print();
  endtask

endclass

`endif
