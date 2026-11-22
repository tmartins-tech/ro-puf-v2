# SPDX-License-Identifier: Apache-2.0
"""RO-PUF V2: RTL/gate-level disabled-state smoke tests.

Do not enable the physical feedback loops in ideal RTL simulation.
These tests do not measure frequency or establish physical RO oscillation.
"""
import cocotb
from cocotb.triggers import Timer


async def check_disabled(dut, label):
    await Timer(1000, unit="ns")
    assert int(dut.uo_out.value) == 0, f"{label}: both outputs must be low"
    assert int(dut.uio_out.value) == 0, f"{label}: uio_out must be zero"
    assert int(dut.uio_oe.value) == 0, f"{label}: all uio pins must be inputs"


@cocotb.test()
async def test_v2_reset_and_disabled_states(dut):
    dut.clk.value = 0       # Clock unused by ring oscillators
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 0
    dut.rst_n.value = 0
    await check_disabled(dut, "initial reset")

    # Local enable asserted, but Tiny Tapeout enable is low.
    dut.rst_n.value = 1
    dut.ui_in.value = 1
    await check_disabled(dut, "global enable low")

    # Global enable asserted, but local enable remains low.
    dut.ui_in.value = 0
    dut.ena.value = 1
    await check_disabled(dut, "local RO_ENABLE low")

    # With both enables requested, reset still disables the ROs.
    dut.ui_in.value = 1
    dut.rst_n.value = 0
    await check_disabled(dut, "reset active")

    dut._log.info("RO-PUF V2 safe disabled-state checks passed; physical frequencies untested.")
