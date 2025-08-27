# High-Speed UART DMA Driver (uart_dma_driver)

## An AXI-Stream VHDL IP Core for High-Throughput Serial Communication

This is a high-speed, configurable UART VHDL IP core for FPGAs, built to interface directly with a Xilinx AXI DMA in Simple Interrupt Mode.  
It features a dual-clock architecture with integrated FIFOs, allowing the AXI and UART logic to operate in separate clock domains for maximum performance.

---

## Core Architecture: A Dual-Clock Design

The driver acts as a robust bridge between the AXI system clock domain and the UART's serial clock domain.  
Integrated Clock-Domain Crossing (CDC) FIFOs ensure safe data buffering and transfer between the two.

### Transmit Flow
```
AXI DMA (MM2S) --> [ TX FIFO (AXI Clock Domain) ] --> UART TX Logic (UART Clock Domain) --> External Pin
```

### Receive Flow
```
External Pin --> UART RX Logic (UART Clock Domain) --> [ RX FIFO (AXI Clock Domain) ] --> AXI DMA (S2MM)
```

---

## Key Features

| Feature | Description |
|---------|-------------|
| 🚀 High-Speed Operation | Supports baud rates up to 12 Mbps, limited only by the target hardware's capabilities. |
| ↔️ Dual-Clock Design | Isolates AXI (`axis_aclk`) and UART (`clock`) logic for maximum timing flexibility and performance. |
| ⚙️ Fully Configurable | Easily set the baud rate, FIFO depth, and data width using VHDL generics. |
| 📊 Debug Ready | Optional output ports provide real-time FIFO status for easy debugging and system monitoring. |

---

## Performance Capabilities

The driver is capable of handling a wide range of standard and custom baud rates, enabling high-throughput applications.

| Speed Category | Example Baud Rate |
|----------------|-------------------|
| Standard       | 115.2 Kbps        |
| High-Speed     | 921.6 Kbps        |
| Very-High Speed| 3 Mbps            |
| Ultra-High Speed | 12 Mbps         |

---

## Configuration (VHDL Generics)

The core's behavior is controlled by these generics, which must be set upon instantiation.

| Generic Name | Type    | Description |
|--------------|---------|-------------|
| DEBUG_ON     | boolean | Optional. Set to `true` to enable the debug output ports. Defaults to `false`. |
| baudRate     | integer | Required. The desired communication speed in bits per second (e.g., 115200, 12000000). |
| clk_Mhz      | integer | Required. The frequency of the input clock in MHz. Used for baud rate generation. |
| FIFO_DEPTH   | integer | Optional. The depth of the internal TX and RX FIFOs. Defaults to 1024. |
| dataWidth    | integer | Optional. The data width for the UART. Defaults to 8. |

---

## Simple Integration Steps

1. **Instantiate IPs**: Add this `uart_dma_driver` and a standard AXI DMA to your Vivado block design.  
2. **Configure DMA**: Set the AXI DMA to *Simple Mode* (Scatter/Gather disabled) with an 8-bit stream width.  
3. **Connect Clocks & Resets**: Wire up `axis_aclk` to your AXI system clock and `clock` to your UART clock source.  
4. **Connect AXI-Streams**:  
   - Link the DMA's `M_AXIS_MM2S` to the driver's `s_axis_tdata` (and related signals).  
   - Link the driver's `m_axis_tdata` (and related signals) to the DMA's `S_AXIS_S2MM`.  
5. **Connect Physical Pins in the BD**: Route `i_data` (RX) and `data_out` (TX) to your target FPGA pins.

---

## Port Descriptions

| Port Name     | Direction | Width | Description |
|---------------|-----------|-------|-------------|
| clock         | in        | 1     | Clock for the UART logic. |
| axis_aclk     | in        | 1     | Clock for the AXI-Stream interface. |
| resetN        | in        | 1     | Active-low reset for the UART clock domain. |
| axis_resetn   | in        | 1     | Active-low reset for the AXI-Stream clock domain. |
| i_data        | in        | 1     | Serial receive data pin (RX). |
| data_out      | out       | 1     | Serial transmit data pin (TX). |
| m_axis_tdata  | out       | 8     | RX Data to AXI DMA. |
| s_axis_tdata  | in        | 8     | TX Data from AXI DMA. |
| (...others)   | -         | -     | See VHDL entity for full list. |
