--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : flopr.vhd
-- Description: This file defines a flip-flop component named 'flopr'.
-- It is a generic resettable flip-flop (asynchronous, active-high reset) used
-- in digital circuits.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration of flopr
ENTITY flopr IS
  GENERIC (
    DATA_WIDTH : INTEGER := 6 -- Generic parameter to define bit DATA_WIDTH, default is 6 bits
  );
  PORT (
    clk, reset : IN STD_LOGIC; -- Clock and reset signals
    d : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- Input data
    q : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) -- Output data
  );
END flopr;

-- Architecture definition of flopr, specifying its behavior
ARCHITECTURE asynchronous OF flopr IS
BEGIN
  PROCESS (clk, reset) BEGIN
    IF reset = '1' THEN
      q <= (OTHERS => '0'); -- Reset logic, clears the output
    ELSIF rising_edge(clk) THEN
      q <= d; -- Data transfer on rising edge of the clock
    END IF;
  END PROCESS;
END;
