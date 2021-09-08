library IEEE;
use IEEE.STD_LOGIC_1164.all;

use IEEE.NUMERIC_STD.all;

library work;
use work.tb_types.all;

entity tb_WasmFpgaDebug is
    generic (
        stimulus_path : string := "../../../../../simstm/";
        stimulus_file : string := "WasmFpgaDebug.stm"
    );
end;

architecture behavioural of tb_WasmFpgaDebug is

    constant CLK100M_PERIOD : time := 10 ns;

    signal Clk100M : std_logic := '0';
    signal Rst : std_logic := '1';
    signal nRst : std_logic := '0';

    signal WasmFpgaDebug_FileIo : T_WasmFpgaDebug_FileIo;
    signal FileIo_WasmFpgaDebug : T_FileIo_WasmFpgaDebug;

    signal Uart_Adr : std_logic_vector(23 downto 0);
    signal Uart_Sel : std_logic_vector(3 downto 0);
    signal Uart_DatIn: std_logic_vector(31 downto 0);
    signal Uart_We : std_logic;
    signal Uart_Stb : std_logic;
    signal Uart_Cyc : std_logic_vector(0 downto 0);
    signal Uart_DatOut : std_logic_vector(31 downto 0);
    signal Uart_Ack : std_logic;

    component tb_FileIo is
        generic (
            stimulus_path: in string;
            stimulus_file: in string
        );
        port (
            Clk : in std_logic;
            Rst : in std_logic;
            WasmFpgaDebug_FileIo : in T_WasmFpgaDebug_FileIo;
            FileIo_WasmFpgaDebug : out T_FileIo_WasmFpgaDebug
        );
    end component;

    component WasmFpgaDebug
      port (
        Clk : in std_logic;
        nRst : in std_logic;
        Debug_Adr : out std_logic_vector(23 downto 0);
        Debug_Sel : out std_logic_vector(3 downto 0);
        Debug_DatIn: out std_logic_vector(31 downto 0);
        Debug_We : out std_logic;
        Debug_Stb : out std_logic;
        Debug_Cyc : out std_logic_vector(0 downto 0);
        Debug_DatOut : in std_logic_vector(31 downto 0);
        Debug_Ack : in std_logic;
        Uart_Adr : out std_logic_vector(23 downto 0);
        Uart_Sel : out std_logic_vector(3 downto 0);
        Uart_DatIn: out std_logic_vector(31 downto 0);
        Uart_We : out std_logic;
        Uart_Stb : out std_logic;
        Uart_Cyc : out std_logic_vector(0 downto 0);
        Uart_DatOut : in std_logic_vector(31 downto 0);
        Uart_Ack : in std_logic
      );
    end component;

    component tb_UartModel is
      port (
        Clk : in std_logic;
        Rst : in std_logic;
        Uart_Adr : in std_logic_vector(23 downto 0);
        Uart_Sel : in std_logic_vector(3 downto 0);
        Uart_DatIn: in std_logic_vector(31 downto 0);
        Uart_We : in std_logic;
        Uart_Stb : in std_logic;
        Uart_Cyc : in std_logic_vector(0 downto 0);
        Uart_DatOut : out std_logic_vector(31 downto 0);
        Uart_Ack : out std_logic
      );
    end component;

begin

	nRst <= not Rst;

    Clk100MGen : process is
    begin
        Clk100M <= not Clk100M;
        wait for CLK100M_PERIOD / 2;
    end process;

    RstGen : process is
    begin
        Rst <= '1';
        wait for 100ns;
        Rst <= '0';
        wait;
    end process;

    tb_FileIo_i : tb_FileIo
        generic map (
            stimulus_path => stimulus_path,
            stimulus_file => stimulus_file
        )
        port map (
            Clk => Clk100M,
            Rst => Rst,
            WasmFpgaDebug_FileIo => WasmFpgaDebug_FileIo,
            FileIo_WasmFpgaDebug => FileIo_WasmFpgaDebug
        );

    WasmFpgaDebug_i : WasmFpgaDebug
      port map (
        Clk => Clk100M,
        nRst => nRst,
        Debug_Adr => open,
        Debug_Sel => open,
        Debug_DatIn => open,
        Debug_We => open,
        Debug_Stb => open,
        Debug_Cyc => open,
        Debug_DatOut => (others => '0'),
        Debug_Ack => '1',
        Uart_Adr => Uart_Adr,
        Uart_Sel => Uart_Sel,
        Uart_DatIn => Uart_DatIn,
        Uart_We => Uart_We,
        Uart_Stb => Uart_Stb,
        Uart_Cyc => Uart_Cyc,
        Uart_DatOut => Uart_DatOut,
        Uart_Ack => Uart_Ack
      );

    UartModel_i : tb_UartModel
      port map (
        Clk => Clk100M,
        Rst => Rst,
        Uart_Adr => Uart_Adr,
        Uart_Sel => Uart_Sel,
        Uart_DatIn => Uart_DatIn,
        Uart_We => Uart_We,
        Uart_Stb => Uart_Stb,
        Uart_Cyc => Uart_Cyc,
        Uart_DatOut => Uart_DatOut,
        Uart_Ack => Uart_Ack
      );

end;
