library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library my_lib;
use my_lib.math_utils.all;   -- <<< bring in clog2
library xpm;
use xpm.vcomponents.all;
entity fifo_to_axis is
  generic (
    DATA_WIDTH : integer := 32;
    FIFO_DEPTH : integer := 1024
  );
  port (
    -- clock & async-active-high reset
    write_aclk       : in  std_logic;
    m_axis_aclk       : in  std_logic;
    write_resetn    : in  std_logic;
    read_resetn    : in  std_logic;
    s2mm_prmry_reset_n  : in std_logic;
    -- native FIFO write-side
    fifo_wr_data : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    fifo_wr_en   : in  std_logic;
    fifo_full    : out std_logic;
    fifo_empty   : out std_logic;
    fifo_data_count: out std_logic_vector( 16 downto 0):=(others=>'0');--the maximum length
    -- AXI-Stream master interface
    m_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic;
    m_axis_tlast  : out std_logic
  );
end entity fifo_to_axis;


architecture rtl of fifo_to_axis is

  -- Calculate the required width for the data_count signal from XPM FIFO.
  -- XPM data_count port width is ceil(log2(FIFO_WRITE_DEPTH + 1)).
  constant ACTUAL_DATA_COUNT_WIDTH : integer := clog2(FIFO_DEPTH+1);

  -- Internal signals
  signal fifo_dout         : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal sig_fifo_empty    : std_logic;
  signal fifo_rd_en        : std_logic;
  signal sig_fifo_data_count : std_logic_vector(ACTUAL_DATA_COUNT_WIDTH-1 downto 0);
  signal fifo_almost_empty: std_logic;
  -- Optional internal signals for XPM outputs you might want to use or monitor
  signal sig_overflow      : std_logic;
  signal sig_underflow     : std_logic;
  signal active_high_src_rst_write : std_logic;--the write source original reset
  signal active_high_sync_rst_write : std_logic;--the write reset to the fifo
  signal active_high_src_rst_read : std_logic;--the read source original reset
  signal active_high_sync_rst_read : std_logic;--the read reset to the fifo
  signal active_high_combined_rst : std_logic;--the combines OR reset to the internal fifo
  signal sig_axis_tlast: std_logic:='0'; --signal of tLAST
  signal isDMArdy: std_logic_vector(1 downto 0):="01";
  signal cnt: integer :=0;--counting the data words until asserting tLAST
  signal state: std_logic_vector(2 downto 0) :="000";
  signal sig_m_axis_tvalid: std_logic:='0'; --signal of tVALID
  
begin
    active_high_src_rst_write<=not(write_resetn);  -- Create an active-high reset for the XPM FIFO.
    active_high_src_rst_read<=not(read_resetn);  -- Create an active-high reset for the XPM FIFO.
    m_axis_tlast<=sig_axis_tlast;
    active_high_combined_rst<=active_high_sync_rst_write or active_high_sync_rst_read;
  -- Note: The rst port of xpm_fifo_sync is synchronous to wr_clk/rd_clk.
  -- For robust design, an asynchronously asserted, synchronously deasserted reset
  -- derived from 'aresetn' and 'aclk' is recommended.
  -- For simplicity here, we are directly using an active-high version.
    rst_sync_writeCLK:xpm_cdc_sync_rst
    port map (
       dest_clk =>  write_aclk,
       src_rst=>active_high_src_rst_write,
       dest_rst=> active_high_sync_rst_write   
    );
     rst_sync_readCLK:xpm_cdc_sync_rst
    port map (
       dest_clk =>  m_axis_aclk,
       src_rst=>active_high_src_rst_read,
       dest_rst=> active_high_sync_rst_read   
    );
  -- Instantiate the XPM Asynchronous FIFO
  fifo_xpm_i : xpm_fifo_async
    generic map (
      -- FIFO Primitive Configuration
      FIFO_MEMORY_TYPE        => "auto",    -- "auto", "block", "distributed", "ultra"
      FIFO_WRITE_DEPTH        => FIFO_DEPTH,
      WRITE_DATA_WIDTH        => DATA_WIDTH,
      READ_DATA_WIDTH         => DATA_WIDTH,
      RD_DATA_count_width     =>ACTUAL_DATA_COUNT_WIDTH,
      WR_DATA_count_width     =>ACTUAL_DATA_COUNT_WIDTH,
      -- FIFO Operating Mode
      READ_MODE               => "std",    -- "std" (standard) or "fwft" (first-word fall-through)
      -- FIFO Read Latency (specific to memory type and READ_MODE)
      FIFO_READ_LATENCY=>1
    )
    port map (
      -- Clocks & Reset
      sleep         => '0',
      rst           => active_high_combined_rst,        -- Synchronous reset
      wr_clk        => write_aclk,          -- Write clock
      rd_clk         => m_axis_aclk,          -- read clock
      -- Write Interface
      din           => fifo_wr_data,
      wr_en         => fifo_wr_en,
      full          => fifo_full,
      overflow      => sig_overflow,  -- Optional: connect to monitor
      wr_rst_busy   => open,          -- Optional: Write domain reset busy

      -- Read Interface
      dout          => fifo_dout,
      rd_en         => fifo_rd_en,
      empty         => sig_fifo_empty,
      underflow     => sig_underflow, -- Optional: connect to monitor
      rd_rst_busy   => open,          -- Optional: Read domain reset busy

      -- Data Counts (these ports are standard, width derived from FIFO_WRITE_DEPTH)
      --data_count    => sig_fifo_data_count,
      rd_data_count => sig_fifo_data_count,       -- Optional: Read domain specific data count
      -- wr_data_count => open,       -- Optional: Write domain specific data count

      -- Programmable Flags (require USE_ADV_FEATURES configuration)
      prog_full     => open,          -- prog_full => sig_prog_full,
      prog_empty    => open,          -- prog_empty => sig_prog_empty,
      almost_full   => open,
      almost_empty  => fifo_almost_empty,

       --Error Injection/Correction (optional)
      dbiterr       => open,
      sbiterr       => open,
      injectdbiterr => '0',
      injectsbiterr => '0'
    );
 
  -- AXI-Stream conversion logic

  m_axis_tdata   <= fifo_dout;
  fifo_empty     <= sig_fifo_empty;
  fifo_data_count(ACTUAL_DATA_COUNT_WIDTH-1 downto 0)<= sig_fifo_data_count;
  m_axis_tvalid<=sig_m_axis_tvalid;
  process(m_axis_aclk)
  begin
    if falling_edge(m_axis_aclk) then
      if active_high_combined_rst  = '1' then
        sig_axis_tlast <= '0';
        cnt<=0;
        isDMArdy<="01";
        state<="000";
        fifo_rd_en<='0';
        sig_m_axis_tvalid<='0';
      else  
        if( s2mm_prmry_reset_n='0' and isDMArdy/="11") then--if s2mm reset is done then the axi is ready
           isDMArdy<=std_logic_vector(unsigned(isDMArdy) +1);--the s2mm should be active twice before starting transferring data
        end if;
        if(state="000") then--idle state
            if(isDMArdy="11") then--wait for dma to be initialized 
                state<="001";--s2mm reset should be asserted twice
                cnt<=0;
            end if;
        end if;
        if (state="001") then
          if (sig_fifo_empty='0') then
                fifo_rd_en<='1';--there is more data to be sent 
                state<="010";
                cnt<=cnt+1;
            end if;
        end if;
        if( state="010") then
             if(m_axis_tready='1') then--handshake happens
                  sig_m_axis_tvalid<='1';
                  if( sig_fifo_empty='1' or cnt>=(FIFO_DEPTH)) then
                        sig_axis_tlast<='1';--last data in the packet
                        state<="100";
                        fifo_rd_en<='0';--there is NO more data to be sent  
                  else
                        cnt<=cnt+1;--writing data
                        fifo_rd_en<='1';--there is NO more data to be sent
                  end if;
              else
                  fifo_rd_en<='0';--there is NO more data to be sent
                  sig_m_axis_tvalid<='0';
              end if;              
        end if;
        if( state="100") then
            fifo_rd_en<='0';
                sig_axis_tlast<='0';--the master has accepted the data
                sig_m_axis_tvalid<='0';
                state<="000";--last data in the packet
        end if;
     end if;
    end if;
  end process;
 

end architecture rtl;


 