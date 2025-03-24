----------------------------------------------------------------------------
-- Receptor UART     
-- 
----------------------------------------------------------------------------
-- clk = 100 MHz
-- baudrate = 115200

-- 100MHZ / 62      = 1.612903 MHz
-- 100MHz / 62 / 14 = 115207.4 baud

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity UART_RX is
  port (UART_IN  : in  std_logic;
        CLK      : in  std_logic;
        DATA     : out std_logic_vector (7 downto 0);
        DATA_RDY : out std_logic
        );
end UART_RX;
----------------------------------------------------------------------------
architecture rtl of UART_RX is
  constant t_baud : time := 1 sec / 115200;
  constant t_clk  : time := 1 sec / 100_000_000;

  constant N_BIT       : integer := 8;
  constant div_baud_xN : integer := 62;  -- Divider needed to get baud_xN from clk
                                        -- (has to be 62 for the case depicted)
  constant div_baud    : integer := 14;  -- Divider needed to get baud from
                                         -- baud_xN (i.e. N = 14)


  type rx_state is (waiting, receiving, ready);
  signal pr_state : rx_state := waiting;
  signal nx_state : rx_state;

  signal baud_xN     : std_logic;       -- marker operating at xN baud rate
  signal baud        : std_logic;       -- marker operating at baud rate
  signal baud_xN_cnt : unsigned (7 downto 0) := (others => '0');
  signal baud_cnt    : unsigned (7 downto 0) := (others => '0');
  signal baud_rst    : std_logic;  --resets baud_cnt when start bit received

  signal bit_cnt : unsigned (3 downto 0);

  signal sample  : std_logic;
  signal rx_data : std_logic_vector(9 downto 0);
----------------------------------------------------------------------------
begin

  process(clk)
  begin
    if rising_edge(clk) then
      pr_state <= nx_state;
    end if;
  end process;

  nx_state_process : process(all)
  begin
    nx_state <= pr_state;
    baud_rst <= '0';
    case pr_state is
      when waiting =>
        if UART_IN = '0' then
          nx_state <= receiving;
          baud_rst <= '1';
        end if;
      when receiving =>
        if bit_cnt = N_BIT + 2 then
          nx_state <= ready;
        end if;
      when ready =>
        nx_state <= waiting;
    end case;
  end process;

  DATA_RDY <= '1' when pr_state = ready else '0';

  time_process : process(clk)
  begin
    if rising_edge(clk) then

      --baud_xN
      if (baud_rst = '1') or (baud_xN_cnt = div_baud_xN - 1) then
        baud_xN_cnt <= (others => '0');
      else
        baud_xN_cnt <= baud_xN_cnt + 1;
      end if;

      --baud
      if (baud_rst = '1')               -- reset: do inmediately
        or
        ((baud_xN = '1') and (baud_cnt = div_baud -1))  -- last count: do if
                                                        -- marker says so
      then
        baud_cnt <= (others => '0');
      else
        if (baud_xN = '1') then
          baud_cnt <= baud_cnt + 1;
        end if;
      end if;
    end if;

  end process;
  baud_xN <= '1' when baud_xN_cnt = 0 else '0';
  baud    <= '1' when baud_cnt = 0    else '0';

  sample <= '1' when (baud_cnt = div_baud/2) and (baud_xn = '1') else '0';

  store_process : process(clk)
  begin
    if rising_edge(clk) then
      if baud_rst = '1' then
        bit_cnt <= (others => '0');
      elsif sample = '1' then
        bit_cnt <= bit_cnt + 1;
        rx_data <= UART_IN & rx_data(rx_data'high downto 1);

      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if nx_state = ready then
        DATA <= rx_data(8 downto 1);
      end if;
    end if;
  end process;


end architecture rtl;
