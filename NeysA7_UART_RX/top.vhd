---------------------------------------------------------
-- UART_RX_CTRL
-- Top entity
-- Pere Palà Schönwälder March 2025
---------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port(
    CLK100MHZ : in  std_logic;
    LED       : out std_logic_vector(15 downto 0);
    JD        : in  std_logic_vector(7 downto 0);  --JD Has to be UPPERCASE to
                                                   --match .xdc file !!!!!!
    JC        : out std_logic_vector(7 downto 0)
    );
end entity top;

architecture rtl of top is
  signal UART_RX  : std_logic;
  signal DATA     : std_logic_vector (7 downto 0);
  signal topREADY : std_logic;
  signal clk      : std_logic;
  constant div_baud_xN : integer := 62;  -- Divider needed to get baud_xN from clk
                                        -- (has to be 62 for the case depicted)
  constant div_baud    : integer := 14;  -- Divider needed to get baud from baud_xN
                                         -- (i.e. N = 14)
  constant N_BIT       : integer := 8;


  -- signal baud_xN     : std_logic;       -- marker operating at xN baud rate
  -- signal baud        : std_logic;       -- marker operating at baud rate


  signal sync_stage_1 : std_logic;  -- First synchronizer stage
  signal sync_stage_2 : std_logic;  -- Second synchronizer stage
begin
  clk     <= CLK100MHZ;
  UART_RX <= sync_stage_2;
  LED     <= UART_RX & topREADY & "000000" & DATA;

  -- JC(0) <= baud;
  -- JC(1) <= baud_xN;

  process(clk)
  begin
    if rising_edge(clk) then
      sync_stage_1 <= JD(0);
      sync_stage_2 <= sync_stage_1;
    end if;
  end process;

   uart : entity work.UART_RX
    port map (
      clk      => clk,
      DATA     => DATA,
      DATA_RDY => topREADY,
      UART_IN  => UART_RX
      );

end architecture rtl;
