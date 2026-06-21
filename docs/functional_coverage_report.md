# Functional Coverage Report

- Parsed logs: 73
- Covered bins: 29/29
- Functional coverage: 100.00%

| Area | Bin | Count | Covered? | Example tests |
|---|---|---:|---|---|
| Traffic | LOCAL transactions | 75 | YES | reserved_high_bits_drop_test, local_seq_zero_drop_test, local_remote_switching_test, local_seq_non1_valid_test, local_seq_max_valid_test |
| Traffic | REMOTE transactions | 107 | YES | remote_three_fragment_3_1_2_test, remote_reserved_high_bits_drop_test, remote_design_seq_index_merge_test, local_remote_switching_test, remote_three_fragment_in_order_test |
| Fields | seq_num | 197 | YES | reserved_high_bits_drop_test, remote_three_fragment_3_1_2_test, remote_reserved_high_bits_drop_test, remote_design_seq_index_merge_test, local_remote_switching_test |
| Fields | frag_num | 91 | YES | reserved_high_bits_drop_test, local_seq_zero_drop_test, remote_three_fragment_3_1_2_test, remote_reserved_high_bits_drop_test, remote_design_seq_index_merge_test |
| Fields | payload_len | 97 | YES | reserved_high_bits_drop_test, local_seq_zero_drop_test, remote_three_fragment_3_1_2_test, remote_reserved_high_bits_drop_test, remote_design_seq_index_merge_test |
| Fields | payload | 489 | YES | remote_three_fragment_3_1_2_test, remote_design_seq_index_merge_test, remote_three_fragment_in_order_test, remote_two_fragment_in_order_test, remote_seq_mismatch_drop_test |
| Payload length | payload_len == 0 | 10 | YES | payload_len_zero_drop_test, remote_payload_len_zero_drop_test, random_all_cases_test, random_all_cases_test |
| Payload length | payload_len == 1 | 154 | YES | reserved_high_bits_drop_test, local_seq_zero_drop_test, remote_three_fragment_3_1_2_test, remote_reserved_high_bits_drop_test, remote_design_seq_index_merge_test |
| Payload length | payload_len 2..4 | 6 | YES | remote_multi_byte_test, local_multi_byte_test, random_all_cases_test, random_all_cases_test |
| Payload length | payload_len > 4 | 12 | YES | local_payload_len_large_valid_test, remote_payload_len_large_valid_test, random_all_cases_test, local_payload_len_large_valid_test, remote_payload_len_large_valid_test |
| Local cfg | valid local cfg | 32 | YES | local_remote_switching_test, local_seq_non1_valid_test, local_seq_max_valid_test, local_payload_len_large_valid_test, local_basic_test |
| Local cfg | local seq zero | 5 | YES | local_seq_zero_drop_test, random_all_cases_test, random_all_cases_test |
| Local cfg | invalid local frag | 12 | YES | local_frag_zero_drop_test, drop_count_accumulation_test, local_invalid_frag_test, random_all_cases_test, drop_count_accumulation_test |
| Remote cfg | valid remote cfg | 75 | YES | remote_three_fragment_3_1_2_test, remote_design_seq_index_merge_test, local_remote_switching_test, remote_three_fragment_in_order_test, remote_two_fragment_in_order_test |
| Remote cfg | remote seq zero | 7 | YES | remote_seq_zero_drop_test, remote_drop_recovery_test, random_all_cases_test, remote_drop_recovery_test, random_all_cases_test |
| Remote cfg | remote frag zero | 5 | YES | remote_frag_zero_drop_test, random_all_cases_test, random_all_cases_test |
| Errors | reserved bits error | 36 | YES | reserved_high_bits_drop_test, remote_reserved_high_bits_drop_test, reserved_bits_drop_test, drop_count_accumulation_test, remote_reserved_mid_bits_drop_test |
| Errors | drop count observed | 81 | YES | reserved_high_bits_drop_test, local_seq_zero_drop_test, remote_reserved_high_bits_drop_test, payload_len_zero_drop_test, reserved_bits_drop_test |
| Backpressure | local backpressure | 2 | YES | local_backpressure_test, local_backpressure_test |
| Backpressure | remote backpressure | 2 | YES | remote_backpressure_test, remote_backpressure_test |
| Reset | reset initial | 2 | YES | reset_initial_test, reset_initial_test |
| Reset | reset after drop | 2 | YES | reset_after_drop_test, reset_after_drop_test |
| Remote merge | remote single fragment | 1 | YES | remote_single_fragment_test |
| Remote merge | remote two fragments in order | 1 | YES | remote_two_fragment_in_order_test |
| Remote merge | remote two fragments out order | 1 | YES | remote_two_fragment_out_of_order_test |
| Remote merge | remote three fragments | 2 | YES | remote_three_fragment_3_1_2_test, remote_three_fragment_in_order_test |
| Remote drop | remote seq mismatch drop | 1 | YES | remote_seq_mismatch_drop_test |
| Remote drop | remote new pkt incomplete drop | 1 | YES | remote_new_packet_while_incomplete_drop_test |
| Reset | reset during remote accumulation | 1 | YES | reset_during_remote_accumulation_test |
