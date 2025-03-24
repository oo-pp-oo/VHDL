----------------------------------------------------------------------------
-- UART signal generator
-- Pere Palà Schönwälder
-- March 2025  
-- Generate UART packets at arbitrary times with arbitray data
--
-- Uses a procedure that generates waveforms with weak drivers outside
-- of the data position. They can be arbitrarily superimposed as long as
-- the data packets don't overlap in time
--
-- Sample usage:           
--   uart_tx_byte(   2 us, t_baud, d1, s);
--   uart_tx_byte( 100 us, t_baud, d2, s);  -- Always the same signal: s
--   ...
--   sr <= s or '0';                        -- Resolves 'H' to '1' if needed    
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

package UART_generator is
  procedure uart_tx_byte(
    constant t_start :     time;
    constant t_bit   :     time;
    constant data    :     std_logic_vector(7 downto 0);
    signal sig_out   : out std_logic
    );
end UART_generator;
----------------------------------------------------------------------------
package body UART_generator is
  procedure uart_tx_byte(
    constant t_start :     time;
    constant t_bit   :     time;
    constant data    :     std_logic_vector(7 downto 0);
    signal sig_out   : out std_logic
    ) is
  begin
    sig_out <= 'H';                     -- Idle state

    wait for t_start;                   -- Wait until t_start for start bit
    sig_out <= '0';                     -- Start bit
    wait for t_bit;                     -- Wait one bit period

    for i in 0 to 7 loop                -- Send 8 data bits (LSB first)
      sig_out <= data(i);
      wait for t_bit;
    end loop;

    sig_out <= '1';                     -- Stop bit
    wait for t_bit;

    sig_out <= 'H';                     -- Return to idle
  end procedure;
end UART_generator;
----------------------------------------------------------------------------
