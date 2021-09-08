library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package tb_Types is

    type T_WasmFpgaDebug_FileIo is
    record
        Uart_DatOut : std_logic_vector(31 downto 0);
        Uart_Ack : std_logic;
    end record;

    type T_FileIo_WasmFpgaDebug is
    record
        Uart_Adr : std_logic_vector(23 downto 0);
        Uart_Sel : std_logic_vector(3 downto 0);
        Uart_DatIn : std_logic_vector(31 downto 0);
        Uart_We : std_logic;
        Uart_Stb : std_logic;
        Uart_Cyc : std_logic_vector(0 downto 0);
    end record;

end package;

package body tb_Types is

end package body;
