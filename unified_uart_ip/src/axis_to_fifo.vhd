library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library my_lib;
use my_lib.math_utils.all ;   -- <<< bring in clog2
library xpm;
use xpm.vcomponents.all;
entity axis_to_fifo is
  generic (
    DATA_WIDTH : integer := 32;
    FIFO_DEPTH : integer := 1024--EFFECTIVE DEPTH IS FIFO DEPTH-1
  );
  port (
    ---axi dma ports---
    write_aclk : IN STD_LOGIC;
    write_resetn : IN STD_LOGIC;
    
    -- clock & async-active-high reset
    read_aclk       : in  std_logic;
    read_resetn    : in  std_logic;
    --FIFO_DEPTH : in integer;
    -- native FIFO write-side
    fifo_dout    : out  std_logic_vector(DATA_WIDTH-1 downto 0);
    fifo_rd_en   : in  std_logic;
    fifo_full    : out std_logic;
    fifo_empty   : out std_logic;
    fifo_read_data_count: out std_logic_vector( 16 downto 0):=(others=>'0');--the maximum length
    s_axis_tdata  :  std_logic_vector(DATA_WIDTH-1 downto 0);
    s_axis_tvalid :in std_logic;
    s_axis_tlast :in std_logic;
    s_axis_tready :out std_logic
  );
end entity axis_to_fifo;


architecture rtl of axis_to_fifo is

  -- Calculate the required width for the data_count signal from XPM FIFO.
  -- XPM data_count port width is ceil(log2(FIFO_WRITE_DEPTH + 1)).
  constant ACTUAL_DATA_COUNT_WIDTH : integer := clog2(FIFO_DEPTH+1);
  -- Internal signals
  --signal fifo_din         : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal sig_fifo_empty    : std_logic;
  signal sig_fifo_wr_en        : std_logic;
  signal sig_fifo_data_count : std_logic_vector(ACTUAL_DATA_COUNT_WIDTH-1 downto 0);
  signal sig_fifo_full  : std_logic;
  -- Optional internal signals for XPM outputs you might want to use or monitor
  signal sig_overflow      : std_logic;
  signal sig_underflow     : std_logic;
  signal active_high_src_rst_write : std_logic;--the write source original reset
  signal active_high_sync_rst_write : std_logic;--the write reset to the fifo
  signal active_high_src_rst_read : std_logic;--the read source original reset
  signal active_high_sync_rst_read : std_logic;--the read reset to the fifo
  signal active_high_combined_rst : std_logic;--the combines OR reset to the internal fifo
  signal sig_axis_tlast: std_logic:='0'; --signal of tLAST
  --signal write_resetn    :std_logic;
   -- AXI-Stream master interface
 
  signal sig_s_axis_tvalid : std_logic;
  signal sig_s_axis_tready :  std_logic;
  
begin
    active_high_src_rst_write<=not(write_resetn);  -- Create an active-high reset for the XPM FIFO.
    active_high_src_rst_read<=not(read_resetn);  -- Create an active-high reset for the XPM FIFO.
    active_high_combined_rst<=active_high_sync_rst_write or active_high_sync_rst_read;
  -- Note: The rst port of xpm_fifo_sync is synchronous to wr_clk/rd_clk.
  -- For robust design, an asynchronously asserted, synchronously deasserted reset
  -- derived from 'aresetn' and 'aclk' is recommended.
    rst_sync_writeCLK:xpm_cdc_sync_rst
    port map (
       dest_clk =>  write_aclk,
       src_rst=>active_high_src_rst_write,
       dest_rst=> active_high_sync_rst_write   
    );
     rst_sync_readCLK:xpm_cdc_sync_rst
    port map (
       dest_clk =>  read_aclk,
       src_rst=>active_high_src_rst_read,
       dest_rst=> active_high_sync_rst_read   
    );  
  -- Instantiate the XPM Asynchronous FIFO
  fifo_xpm_i : xpm_fifo_async
    generic map (
      -- FIFO Primitive Configuration
      FIFO_MEMORY_TYPE        => "block",    -- "auto", "block", "distributed", "ultra"
      FIFO_WRITE_DEPTH        => FIFO_DEPTH,
      WRITE_DATA_WIDTH        => DATA_WIDTH,
      READ_DATA_WIDTH         => DATA_WIDTH,
      WR_DATA_count_width     =>ACTUAL_DATA_COUNT_WIDTH,
      RD_DATA_count_width     =>ACTUAL_DATA_COUNT_WIDTH,     
      -- FIFO Operating Mode
      READ_MODE               => "std",    -- "std" (standard) or "fwft" (first-word fall-through)
	  FIFO_READ_LATENCY=>1
      -- FIFO Read Latency (specific to memory type and READ_MODE)
    )
    port map (
      -- Clocks & Reset
      sleep         => '0',
      rst           => active_high_combined_rst,        -- Synchronous reset
      wr_clk        => write_aclk,          -- Write clock
      rd_clk         => read_aclk,          -- read clock
      -- Write Interface
      din           => s_axis_tdata,
      wr_en         => sig_fifo_wr_en,
      full          => sig_fifo_full,
      overflow      => sig_overflow,  -- Optional: connect to monitor
      wr_rst_busy   => open,          -- Optional: Write domain reset busy

      -- Read Interface
      dout          => fifo_dout,
      rd_en         => fifo_rd_en,
      empty         => sig_fifo_empty,
      underflow     => sig_underflow, -- Optional: connect to monitor
      rd_rst_busy   => open,          -- Optional: Read domain reset busy

      -- Data Counts (these ports are standard, width derived from FIFO_WRITE_DEPTH)
      rd_data_count => sig_fifo_data_count,       -- Optional: Read domain specific data count
      -- wr_data_count => open,       -- Optional: Write domain specific data count

      -- Programmable Flags (require USE_ADV_FEATURES configuration)
      prog_full     => open,         
      prog_empty    => open,          
      almost_full   => open,
      almost_empty  => open,

       --Error Injection/Correction (optional)
      dbiterr       => open,
      sbiterr       => open,
      injectdbiterr => '0',
      injectsbiterr => '0'
    );
  -- AXI-Stream conversion logic
  sig_s_axis_tvalid<=s_axis_tvalid;
  s_axis_tready<=sig_s_axis_tready;
  fifo_empty     <= sig_fifo_empty;
  fifo_read_data_count(ACTUAL_DATA_COUNT_WIDTH-1 downto 0)<= sig_fifo_data_count;
  fifo_full<=sig_fifo_full;
  sig_s_axis_tready<=not(sig_fifo_full);
  sig_fifo_wr_en<=sig_s_axis_tvalid and sig_s_axis_tready;
 

end architecture rtl;


 