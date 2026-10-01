--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : top.vhd
-- Description: Complete single-cycle MIPS system: processor core + instruction
-- memory + data memory. The core outputs are exposed so that a testbench can
-- observe every store (memwrite / dataadr / writedata) and the program counter.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration of top (processor + memories)
ENTITY top IS
    GENERIC (
        IMEM_ADDR_SIZE : INTEGER := 6; -- Instruction memory holds 2**IMEM_ADDR_SIZE words
        DMEM_SIZE : INTEGER := 64; -- Data memory size in words
        PROGRAM : STRING := "" -- Program file loaded into imem ("" = built-in demo program)
    );
    PORT (
        clk, reset : IN STD_LOGIC;
        pc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Program counter
        writedata, dataadr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Data memory write data / address
        memwrite : OUT STD_LOGIC -- Data memory write enable
    );
END;

ARCHITECTURE test OF top IS
    SIGNAL pc_s, instr, readdata : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL writedata_s, dataadr_s : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL memwrite_s : STD_LOGIC;
BEGIN
    -- Processor core
    cpu : ENTITY work.mips
        PORT MAP(
            clk => clk,
            reset => reset,
            pc => pc_s,
            instr => instr,
            memwrite => memwrite_s,
            aluout => dataadr_s,
            writedata => writedata_s,
            readdata => readdata
        );

    -- Instruction memory, word addressed: the PC is a byte address
    imem : ENTITY work.imem
        GENERIC MAP(ADDR_SIZE => IMEM_ADDR_SIZE, INIT_FILE => PROGRAM)
        PORT MAP(a => pc_s(IMEM_ADDR_SIZE + 1 DOWNTO 2), rd => instr);

    -- Data memory
    dmem : ENTITY work.dmem
        GENERIC MAP(MEM_SIZE => DMEM_SIZE)
        PORT MAP(clk => clk, we => memwrite_s, a => dataadr_s, wd => writedata_s, rd => readdata);

    pc <= pc_s;
    writedata <= writedata_s;
    dataadr <= dataadr_s;
    memwrite <= memwrite_s;
END test;
