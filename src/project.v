/*
 * Tiny Tapeout SKY130 - RO-PUF V2
 * Two independent seven-inverting-stage ring oscillators, with two
 * direct frequency outputs and no multiplexer or frequency divider.
 * Each ring contains six SKY130 inverters and one enable NAND gate.
 *
 * NOTE: ideal digital simulation cannot establish oscillation or frequency.
 * Verify preservation of both feedback rings in the mapped physical netlist.
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none

(* keep_hierarchy = "yes" *)
module ro_puf_v2_ring_7 (
    input  wire en,
    output wire osc_out
);
    (* keep = "true" *) wire [6:0] ring;

    // The NAND is the seventh inverting stage and controls oscillation.
    // en=0: NAND output is 1; en=1: the feedback path is an odd-inversion ring.
    (* keep = "true", dont_touch = "true" *)
    sky130_fd_sc_hd__nand2_1 u_enable (
        .A(ring[6]),
        .B(en),
        .Y(ring[0])
    );

    genvar stage;
    generate
        for (stage = 0; stage < 6; stage = stage + 1) begin : g_inv
            (* keep = "true", dont_touch = "true" *)
            sky130_fd_sc_hd__inv_2 u_inv (
                .A(ring[stage]),
                .Y(ring[stage + 1])
            );
        end
    endgenerate

    assign osc_out = ring[6];
endmodule

module tt_um_ro_puf_2_v2 (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    // ui_in[0] = local enable for both independent oscillators
    // uo_out[0] = raw output of RO0; uo_out[1] = raw output of RO1
    // clk is not required; physical ring delays generate oscillations.
    wire run = ena & rst_n & ui_in[0];

    (* keep = "true" *) wire [1:0] oscillator_signals;
    genvar ro_index;
    generate
        for (ro_index = 0; ro_index < 2; ro_index = ro_index + 1) begin : g_ro
            (* keep = "true", dont_touch = "true" *)
            ro_puf_v2_ring_7 u_ring (
                .en(run),
                .osc_out(oscillator_signals[ro_index])
            );
        end
    endgenerate

    // Two dedicated outputs, one per oscillator; forced low when disabled.
    assign uo_out = {6'b000000, (run & oscillator_signals[1]),
                                (run & oscillator_signals[0])};
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

    wire _unused = &{clk, ui_in[7:1], uio_in, 1'b0};
endmodule

`default_nettype wire
