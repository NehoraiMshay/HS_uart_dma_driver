library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_dma_driver is
  generic(   DEBUG_ON : boolean :=false;
             baudRate:integer:=115200;
             clk_Mhz: integer:=100;--default 100Mhz
             FIFO_DEPTH: integer:=1024;
             dataWidth:integer:=8);
  
  Port ( clock : IN STD_LOGIC;
         axis_aclk : IN STD_LOGIC;
         resetN : IN STD_LOGIC;
         axis_resetn : IN STD_LOGIC;
         s2mm_prmry_reset_n : IN STD_LOGIC;
         i_data : IN STD_LOGIC;
         -----------axi ports
         m_axis_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
         m_axis_tvalid : OUT STD_LOGIC;
         m_axis_tready : IN STD_LOGIC;
         m_axis_tlast : OUT std_logic;
         s_axis_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
         s_axis_tvalid : IN STD_LOGIC;
         s_axis_tlast : IN STD_LOGIC;
         s_axis_tready : OUT STD_LOGIC;
         data_out    : OUT STD_LOGIC;
         ---------------------debug ports
         debug_fifo_TX_empty:out std_logic;
         debug_fifo_TX_data_count:out std_logic_vector( 16 downto 0);
         debug_fifo_TX_full:out std_logic;  
         debug_fifo_RX_empty :out STD_LOGIC;
         debug_fifo_RX_data_count: out std_logic_vector( 16 downto 0);--the maximum length
         debug_invalid_packet :out STD_LOGIC  
         -------------------------
               
          );
end uart_dma_driver;

architecture Behavioral of uart_dma_driver is
signal sig_fifo_TX_full :std_logic; 
signal sig_fifo_TX_empty: std_logic;
signal sig_fifo_TX_data_count :std_logic_vector( 16 downto 0);
signal sig_fifo_RX_empty :std_logic; 
signal sig_invalid_packet: std_logic;
signal sig_fifo_RX_data_count :std_logic_vector( 16 downto 0);
COMPONENT RX
  generic(   
             baudRate:integer:=115200;
             clk_Mhz: integer:=100;--default 100Mhz
             FIFO_DEPTH: integer:=1024;
             dataWidth:integer:=8);
  PORT (
    clock : IN STD_LOGIC;
    m_axis_aclk : IN STD_LOGIC;
    resetN : IN STD_LOGIC;
    m_axis_resetn : IN STD_LOGIC;
    s2mm_prmry_reset_n : IN STD_LOGIC;
    i_data : IN STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tlast : OUT STD_LOGIC;
    debug_fifo_empty : OUT STD_LOGIC;
    debug_fifo_data_count : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    debug_invalid_packet : OUT STD_LOGIC 
  );
END COMPONENT;
COMPONENT TX
   generic(   
             baudRate:integer:=115200;
             clk_Mhz: integer:=100;--default 100Mhz
             FIFO_DEPTH: integer:=1024;
             dataWidth:integer:=8);
  PORT (
    clock : IN STD_LOGIC;
    resetN : IN STD_LOGIC;
    s_axis_aclk : IN STD_LOGIC;
    s_axis_resetN : IN STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tlast : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    debug_fifo_empty : OUT STD_LOGIC;
    debug_fifo_read_data_count : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    debug_fifo_full : OUT STD_LOGIC;
    data_out : OUT STD_LOGIC
  );
END COMPONENT;
begin
 my_rx_dma_driver : RX
   GENERIC MAP (
        baudRate=>baudRate,
        clk_Mhz=>clk_Mhz,
        FIFO_DEPTH =>FIFO_DEPTH,
        dataWidth =>dataWidth       
          )
  PORT MAP (
    clock => clock,
    m_axis_aclk => axis_aclk,
    resetN => resetN,
    m_axis_resetn => axis_resetn,
    s2mm_prmry_reset_n => s2mm_prmry_reset_n,
    i_data => i_data,
    m_axis_tdata => m_axis_tdata,
    m_axis_tvalid => m_axis_tvalid,
    m_axis_tready => m_axis_tready,
    m_axis_tlast => m_axis_tlast,
    debug_fifo_empty => sig_fifo_RX_empty,
    debug_fifo_data_count => sig_fifo_RX_data_count,
    debug_invalid_packet =>sig_invalid_packet
  );
 my_transmitter_dma_driver : TX
   GENERIC MAP (
        baudRate=>baudRate,
        clk_Mhz=>clk_Mhz,
        FIFO_DEPTH =>FIFO_DEPTH,
        dataWidth =>dataWidth       
          )
  PORT MAP (
    clock => clock,
    resetN => resetN,
    s_axis_aclk => axis_aclk,
    s_axis_resetN => axis_resetn,
    s_axis_tdata => s_axis_tdata,
    s_axis_tvalid => s_axis_tvalid,
    s_axis_tlast => s_axis_tlast,
    s_axis_tready => s_axis_tready,
    debug_fifo_empty => sig_fifo_TX_empty,
    debug_fifo_read_data_count => sig_fifo_TX_data_count,
    debug_fifo_full => sig_fifo_TX_full,
    data_out => data_out
  );
  
  G_DEBUG_PORTS : if DEBUG_ON generate
        debug_fifo_TX_empty<=sig_fifo_TX_empty;
        debug_fifo_TX_data_count<=sig_fifo_TX_data_count;
        debug_fifo_TX_full<=sig_fifo_TX_full;
        debug_fifo_RX_empty<=sig_fifo_RX_empty ;
        debug_fifo_RX_data_count<= sig_fifo_RX_data_count;--the maximum length
        debug_invalid_packet<= sig_invalid_packet;  
       else generate
       debug_fifo_TX_empty<='0';
       debug_fifo_TX_full<='0';
       debug_fifo_TX_data_count<=(others=>'0');
       debug_fifo_RX_empty<='0' ;
       debug_fifo_RX_data_count<= (others=>'0');--the maximum length
       debug_invalid_packet<= '0';  
       end generate G_DEBUG_PORTS;
end Behavioral;
