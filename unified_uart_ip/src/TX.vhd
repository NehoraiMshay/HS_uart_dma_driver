library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TX is
    generic( baudRate:integer:=115200;
             clk_Mhz: integer:=100;--default 100Mhz
             FIFO_DEPTH: integer:=1024;
             dataWidth:integer:=8);
    Port ( clock : in STD_LOGIC;
           resetN : in STD_LOGIC;-- active low
           s_axis_aclk: in STD_LOGIC;
           s_axis_resetN : in STD_LOGIC;-- active low
           -------------axi ports
           s_axis_tdata  : in std_logic_vector(dataWidth-1 downto 0);
           s_axis_tvalid :in std_logic;
           s_axis_tlast :in std_logic;
           s_axis_tready :out std_logic;
           ----------------debug ports
           debug_fifo_empty:out std_logic;
           debug_fifo_read_data_count:out std_logic_vector( 16 downto 0);
           debug_fifo_full:out std_logic;    
           -------------------------
           data_out: out std_logic
           );
end TX;

architecture Behavioral of TX is
signal raw_clk:integer:=clk_Mhz*10**6;
constant sendingTime: integer:=raw_clk/baudRate;-- number of rising edges per bit, clock frequency divided by the baud rate 
signal counter: integer:=0;-- counts the number of rising edges
Type TX_states is (startBit,dataBits,idle,stopBit);
SIGNAL State: TX_states:=idle; 
signal index: integer range 0 to dataWidth-1:=0;-- specifying the transmitted data
signal rd_en_sig: std_logic:= '0';-- true when the transmittion has finished
signal process_begin: std_logic:='0';-- high if sending process has began 
signal sig_fifo_empty:  std_logic;-- new data to be sent
signal sig_fifo_full:  std_logic;-- inner fifo is full 
signal data : STD_LOGIC_VECTOR (dataWidth-1 downto 0); --data being received from the fifo
signal sig_fifo_read_data_count: std_logic_vector( 16 downto 0):=(others=>'0');--the maximum length
COMPONENT axis_to_fifo is
  generic (
    DATA_WIDTH : integer := dataWidth;
    FIFO_DEPTH : integer := FIFO_DEPTH--EFFECTIVE DEPTH IS FIFO DEPTH-1
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
    s_axis_tdata  : in std_logic_vector(DATA_WIDTH-1 downto 0);
    s_axis_tvalid :in std_logic;
    s_axis_tlast :in std_logic;
    s_axis_tready :out std_logic
  );
end COMPONENT;
 begin
   my_tx_dma : axis_to_fifo
   GENERIC MAP(
      DATA_WIDTH=>dataWidth,
      FIFO_DEPTH =>FIFO_DEPTH
          )
   PORT MAP (
   write_aclk=>clock,
   write_resetn=>resetN,
   read_aclk=>s_axis_aclk,
   read_resetn =>s_axis_resetN,
   fifo_dout=>data,
   fifo_rd_en=>rd_en_sig,
   fifo_full=>sig_fifo_full,
   fifo_empty=>sig_fifo_empty,
   fifo_read_data_count=>sig_fifo_read_data_count,
   s_axis_tdata=>s_axis_tdata,
   s_axis_tvalid=>s_axis_tvalid,
   s_axis_tlast=>s_axis_tvalid,
   s_axis_tready=>s_axis_tready );
   
     process(clock,resetN)
     begin 
     if ( resetN='0') then
           counter<=0;  
           state<=idle;
           index<=0;
           data_out<='1';
           rd_en_sig<='0';
           process_begin<='0';
      elsif( rising_edge(clock) and (process_begin='1' or sig_fifo_empty='0') ) then-- there is new data in the fifo 
           if(process_begin='0' and rd_en_sig='0')then--no read process has begun
                rd_en_sig<='1';--setting the read enable signal high for a single clock cycle
           else
                rd_en_sig<='0';
           end if;          
           counter<=counter+1;
               case state is        
                    when idle=>      
                                process_begin<='1';
                                if(counter=SendingTime) then  
                                      data_out<='0'; 
                                      counter<=0;   
                                      state<=startBit;
                                end if; 
                    when startBit=>  
                                if(counter=SendingTime) then 
                                      data_out<=data(index); 
                                      index<=index+1; 
                                      counter<=0; 
                                      state<=dataBits; 
                                end if;
                    when dataBits=>  
                                if(counter=SendingTime and index=dataWidth-1) then 
                                      data_out<=data(index); 
                                      counter<=0; 
                                      index<=0; 
                                      state<=stopBit;
                                elsif (counter=SendingTime)  then      
                                      data_out<=data(index); 
                                      counter<=0;
                                      index<=index+1; 
                                end if;  
                    when stopBit=>   
                                if(counter=SendingTime) then   
                                      data_out<='1'; 
                                      counter<=0;
                                      index<=0;
                                      state<=idle;
                                      process_begin<='0';  
                                end if;
               end case;  
      end if;
     end process;     
end Behavioral;
