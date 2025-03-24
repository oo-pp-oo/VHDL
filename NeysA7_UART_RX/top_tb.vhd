----------------------------------------------------------------------------
-- Testbench del modul UART_TX_CTRL
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use work.UART_generator.all;            -- To generate UART signals

entity top_tb is
end top_tb;

architecture Behavioral of top_tb is
  constant t_baud : time := 1 sec / 115200;
  constant t_clk  : time := 1 sec / 100_000_000;

  constant d1 : std_logic_vector(7 downto 0) := "00001111";
  constant d2 : std_logic_vector(7 downto 0) := "01010101";

  signal dataRCVD : std_logic_vector(7 downto 0);
  signal s        : std_logic;

  -- BEGIN BOARD ITEMS
  signal LED       : std_logic_vector (15 downto 0);
  signal CLK100MHZ : std_logic;
  signal JD        : std_logic_vector(7 downto 0);
  signal JC        : std_logic_vector(7 downto 0);
  --END BOARD ITEMS

begin
  dut : entity work.top
    port map (
      CLK100MHZ => CLK100MHZ,
      LED       => LED,
      JD        => JD,
      JC        => JC
      );

  clk_process : process
  begin  --the clock process
    CLK100MHZ <= '0';
    wait for t_clk/2;
    for i in 1 to 20000 loop
      CLK100MHZ <= not CLK100MHZ;
      wait for t_clk/2;
    end loop;
    wait;
  end process clk_process;

  uart_tx_byte(7.1 us, t_baud, d2, s);   -- Send a byte via UART

  JD(0)    <= s or '0';                 -- Resolves 'H' to '1'
  dataRCVD <= LED(7 downto 0);          -- To better view simulation

end architecture Behavioral;
