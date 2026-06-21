`timescale 1ns/1ps
// ============================================================
// BIRD Transaction
// ------------------------------------------------------------
// This class represents one BIRD packet/fragment at a high level.
//
// The driver will later convert this transaction into pin-level
// activity on:
//   in_vld, data_in, cfg
//
// For now, we only create the class and compile it.
// ============================================================

`ifndef BIRD_TRANSACTION_SV
`define BIRD_TRANSACTION_SV

class bird_transaction;

  // ------------------------------------------------------------
  // Traffic type values
  // ------------------------------------------------------------
  typedef enum bit {
    LOCAL_TRAFFIC  = 1'b0,
    REMOTE_TRAFFIC = 1'b1
  } traffic_type_e;

  // ------------------------------------------------------------
  // Basic transaction fields
  // ------------------------------------------------------------
  traffic_type_e traffic_type;

  // Payload bytes for this packet/fragment
  byte unsigned payload[$];

  // CRC bytes that come after the payload on input stream.
  // For local traffic, the spec says these CRC bytes are forwarded
  // unchanged.
  // For remote traffic, the spec says BIRD regenerates CRC16 over the
  // merged payload instead of forwarding the input CRC directly.
  logic [15:0] input_crc;

  // cfg fields
  logic [7:0] payload_len;
  logic [4:0] frag_num;
  logic [4:0] seq_num;

  // Full 32-bit cfg word
  logic [31:0] cfg;

  // If this is not zero, it can be ORed into cfg to make reserved
  // bits invalid.
  logic [31:0] cfg_error_mask;

  // Human-readable name for debug messages
  string name;


  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(string name = "bird_transaction");
    this.name           = name;

    this.traffic_type   = LOCAL_TRAFFIC;
    this.payload.delete();

    this.input_crc      = 16'h0000;

    this.payload_len    = 8'd0;
    this.frag_num       = 5'd0;
    this.seq_num        = 5'd0;

    this.cfg            = 32'h0000_0000;
    this.cfg_error_mask = 32'h0000_0000;
  endfunction


  // ------------------------------------------------------------
  // Build cfg from transaction fields
  // ------------------------------------------------------------
  // cfg format:
  //   bit  [0]     = traffic type
  //   bits [15:8]  = payload length
  //   bits [20:16] = fragment number
  //   bits [28:24] = sequence number
  //
  // Reserved bits should stay zero for valid packets.
  // ------------------------------------------------------------
  function void build_cfg();
    logic [31:0] c;

    c = 32'h0000_0000;

    c[0]     = traffic_type;
    c[15:8]  = payload_len;
    c[20:16] = frag_num;
    c[28:24] = seq_num;

    // Used later for invalid cfg tests.
    c = c | cfg_error_mask;

    cfg = c;
  endfunction


  // ------------------------------------------------------------
  // Configure this transaction as a valid local packet
  // ------------------------------------------------------------
  // Spec rule:
  //   traffic_type = 0
  //   frag_num     = 1
  //   seq_num      = any valid packet sequence number, 1..31
  //
  // Local SEQ_NUM identifies the packet but has no functional impact
  // on local routing.
  //
  // The local packet will be:
  //   payload bytes + two CRC bytes
  // ------------------------------------------------------------
  function void set_valid_local(
    input byte unsigned payload_bytes[$],
    input logic [15:0]  crc_value = 16'h1234,
    input logic [4:0]   sequence_number = 5'd1
  );
    traffic_type = LOCAL_TRAFFIC;

    payload.delete();
    foreach (payload_bytes[i]) begin
      payload.push_back(payload_bytes[i]);
    end

    payload_len = payload.size();
    frag_num    = 5'd1;
    seq_num     = sequence_number;
    input_crc   = crc_value;

    cfg_error_mask = 32'h0000_0000;

    build_cfg();
  endfunction


  // ------------------------------------------------------------
  // Configure this transaction as a remote fragment
  // ------------------------------------------------------------
  // Remote traffic will be used in later steps.
  // For remote traffic:
  //   traffic_type = 1
  //   seq_num must be non-zero
  //   frag_num must be non-zero
  // ------------------------------------------------------------
  function void set_remote_fragment(
    input byte unsigned payload_bytes[$],
    input logic [4:0]   fragment_number,
    input logic [4:0]   sequence_number,
    input logic [15:0]  crc_value = 16'h0000
  );
    traffic_type = REMOTE_TRAFFIC;

    payload.delete();
    foreach (payload_bytes[i]) begin
      payload.push_back(payload_bytes[i]);
    end

    payload_len = payload.size();
    frag_num    = fragment_number;
    seq_num     = sequence_number;
    input_crc   = crc_value;

    cfg_error_mask = 32'h0000_0000;

    build_cfg();
  endfunction


  // ------------------------------------------------------------
  // Return CRC byte 1
  // ------------------------------------------------------------
  // We send CRC as two bytes after the payload.
  // Here we use high byte first:
  //   input_crc[15:8], then input_crc[7:0]
  // ------------------------------------------------------------
  function byte unsigned crc_byte_1();
    return input_crc[15:8];
  endfunction


  // ------------------------------------------------------------
  // Return CRC byte 2
  // ------------------------------------------------------------
  function byte unsigned crc_byte_2();
    return input_crc[7:0];
  endfunction


  // ------------------------------------------------------------
  // Print transaction information
  // ------------------------------------------------------------
  function void print();
    $display("--------------------------------------------------");
    $display("Transaction name : %s", name);
    $display("traffic_type     : %s",
             (traffic_type == LOCAL_TRAFFIC) ? "LOCAL" : "REMOTE");
    $display("payload_len      : %0d", payload_len);
    $display("frag_num         : %0d", frag_num);
    $display("seq_num          : %0d", seq_num);
    $display("input_crc        : 0x%04h", input_crc);
    $display("cfg              : 0x%08h", cfg);

    $write("payload          : ");
    foreach (payload[i]) begin
      $write("%02h ", payload[i]);
    end
    $write("\n");

    $display("--------------------------------------------------");
  endfunction
  
    // ------------------------------------------------------------
  // Configure this transaction as a custom local packet
  // ------------------------------------------------------------
  // This is useful for spec boundary and negative tests.
  //
  // Example:
  //   local packet with frag_num != 1 should be dropped.
  //   local packet with seq_num == 0 should be dropped.
  //   local packet with seq_num in 1..31 should not be dropped
  //   because SEQ_NUM has no functional impact on local routing.
  // ------------------------------------------------------------
  function void set_local_custom(
    input byte unsigned payload_bytes[$],
    input logic [4:0]   custom_frag_num,
    input logic [4:0]   custom_seq_num,
    input logic [15:0]  crc_value = 16'h1234
  );
    traffic_type = LOCAL_TRAFFIC;

    payload.delete();
    foreach (payload_bytes[i]) begin
      payload.push_back(payload_bytes[i]);
    end

    payload_len = payload.size();
    frag_num    = custom_frag_num;
    seq_num     = custom_seq_num;
    input_crc   = crc_value;

    cfg_error_mask = 32'h0000_0000;

    build_cfg();
  endfunction
  
  // Add an error mask to cfg
  
  function void add_cfg_error_mask(input logic [31:0] error_mask);
    cfg_error_mask = error_mask;
    build_cfg();
  endfunction 
  
  function void override_payload_len(input logic [7:0] new_payload_len);
    payload_len = new_payload_len;
    build_cfg();
  endfunction

endclass

`endif
