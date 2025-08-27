library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RX is
    generic( baudRate:integer:=115200;
             clk_Mhz: integer:=100;--default 100Mhz
             FIFO_DEPTH: integer:=1024;
             dataWidth:integer:=8);
    Port ( clock : in STD_LOGIC;
           m_axis_aclk: in STD_LOGIC;
           resetN : in STD_LOGIC;-- active low
           m_axis_resetn: in STD_LOGIC;-- active low
           s2mm_prmry_reset_n: in STD_LOGIC;
           i_data : in STD_LOGIC;
           -----  debug ports
           debug_fifo_empty :out STD_LOGIC;
           debug_fifo_data_count: out std_logic_vector( 16 downto 0);--the maximum length
           debug_invalid_packet :out STD_LOGIC;
           -- AXI-Stream master interface
            m_axis_tdata  : out std_logic_vector(dataWidth-1 downto 0);
            m_axis_tvalid : out std_logic;
            m_axis_tready : in  std_logic;
            m_axis_tlast  : out std_logic
           );
           
end RX;

architecture Behavioral of RX is
signal raw_clk:integer:=clk_Mhz*10**6;--the raw frequency clock
constant recievingTime: integer:=raw_clk/baudRate;-- number of rising edges per bit, clock frequency divided by the baud rate 
signal counter: integer:=0;-- counts the number of rising edges
Type RX_states is (startBit,dataBits,idle,stopBit);
SIGNAL State: RX_states:=idle; 
signal index: integer range 0 to dataWidth-1:=0;-- specifying the transmitted data
signal sig_data: STD_LOGIC_VECTOR(dataWidth-1 downto 0);
signal sig_data_final: STD_LOGIC_VECTOR(dataWidth-1 downto 0);
signal done: std_logic:= '0';-- true when the transmittion has finished WR EN 
signal sig_fifo_full:  STD_LOGIC;
signal sig_fifo_empty:STD_LOGIC;
signal fifo_data_count: std_logic_vector( 16 downto 0);--the maximum length
signal sig_invalid_packet:STD_LOGIC:='0';
COMPONENT fifo_to_axis IS 
    generic (
    DATA_WIDTH : integer := dataWidth;
    FIFO_DEPTH : integer := FIFO_DEPTH
        );
    PORT (
        write_aclk : in std_logic ;
        m_axis_aclk : in std_logic ;
        write_resetn: in std_logic ;
        read_resetn: in std_logic; 
        s2mm_prmry_reset_n : in std_logic; 
        fifo_wr_data: in std_logic_vector(dataWidth-1 downto 0);
        fifo_wr_en : in std_logic ;
        fifo_full    : out std_logic;
        fifo_empty   : out std_logic;
        fifo_data_count: out std_logic_vector( 16 downto 0):=(others=>'0');--the maximum length
        -- AXI-Stream master interface
        m_axis_tdata  : out std_logic_vector(dataWidth-1 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tready : in  std_logic;
        m_axis_tlast  : out std_logic
         );
end COMPONENT;
 begin
     
     
     my_rx_dma : fifo_to_axis 
     GENERIC MAP (
        DATA_WIDTH =>dataWidth,
        FIFO_DEPTH =>FIFO_DEPTH
          )
       PORT MAP (
        write_aclk =>clock,
        m_axis_aclk =>m_axis_aclk,
        write_resetn=>resetN,
        read_resetn=>m_axis_resetn,
        s2mm_prmry_reset_n=>s2mm_prmry_reset_n ,
        fifo_wr_data=>sig_data_final,
        fifo_wr_en =>done,
        fifo_full => sig_fifo_full,
        fifo_empty =>sig_fifo_empty,
        fifo_data_count=>fifo_data_count,
        -- AXI-Stream master interface
        m_axis_tdata =>m_axis_tdata ,
        m_axis_tvalid =>m_axis_tvalid,
        m_axis_tready =>m_axis_tready,
        m_axis_tlast=> m_axis_tlast 
       );
     
     
     process(clock,resetN)
     begin 
     if ( resetN='0' or sig_fifo_full='1') then
           counter<=0;  
           state<=idle;
           index<=0;
           done<='0';
           sig_data<=(others=>'0');
           sig_invalid_packet<='0';
      elsif( rising_edge(clock)) then-- transmitter enabled part- 
           if(state/=idle) then
            counter<=counter+1;
           end if;
               case state is        
                    when idle=>      
                                done<='0';
                                sig_invalid_packet<='0';
                                if(i_data='0') then  
                                      counter<=0;   
                                      state<=startBit;
                                end if; 
                    when startBit=>  
                                if(i_data='1') then
                                   state<=idle;--making sure the startBit is stable for at least bit length/2
                                elsif(counter=recievingTime/2) then
                                      counter<=0; 
                                      state<=dataBits; 
                                end if;
                    when dataBits=>  
                                if(counter=recievingTime and index=dataWidth-1) then 
                                      sig_data(index)<=i_data; 
                                      counter<=0; 
                                      index<=0; 
                                      state<=stopBit;
                                elsif (counter=recievingTime)  then      
                                      sig_data(index)<=i_data; 
                                      counter<=0;
                                      index<=index+1; 
                                end if;  
                    when stopBit=>   
                                if(counter=recievingTime) then
                                      counter<=0;
                                      index<=0;
                                      state<=idle;
                                      if(i_data='1') then--making sure that the stop bit is stable
                                          done<='1'; 
                                          sig_data_final<=sig_data;
                                      else
                                         sig_invalid_packet<='1';
                                      end if;
                                end if;
               end case;  
      end if;
     end process;
    
end Behavioral;
