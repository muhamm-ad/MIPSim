--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : flopr.vhd
-- Description: This file defines a flip-flop component named 'flopr'. 
-- It is a generic synchronous resettable flip-flop used in digital circuits.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

-- Entity declaration of flopr
ENTITY flopr IS
  GENERIC (
    width : INTEGER := 6 -- Generic parameter to define bit width, default is 6 bits
  );
  PORT (
    clk, reset : IN STD_LOGIC; -- Clock and reset signals
    d : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0); -- Input data
    q : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0) -- Output data
  );
END flopr;

-- Architecture definition of flopr, specifying its behavior
ARCHITECTURE asynchronous OF flopr IS
BEGIN
  PROCESS (clk, reset) BEGIN
    IF reset = '1' THEN
      q <= CONV_STD_LOGIC_VECTOR(0, width); -- Reset logic, clears the output
    ELSIF clk'event AND clk = '1' THEN
      q <= d; -- Data transfer on rising edge of the clock
    END IF;
  END PROCESS;
END;