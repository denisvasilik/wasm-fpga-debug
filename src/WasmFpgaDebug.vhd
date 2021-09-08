library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.WasmFpgaDebugPackage.all;

entity WasmFpgaDebug is
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
end;

architecture Behavioural of WasmFpgaDebug is

  constant project : string := "WebAssembly FPGA Debug Core";
  constant version : string := "v0.0.0a0";
  constant commit : string := "0000000";
  constant banner : string := ESC & "[93;1m" & project & " " & version & " - " & commit & ESC & "[0m" & CR & LF;

  signal State : std_logic_vector(7 downto 0);

  signal ReadLine : byte_array(63 downto 0);
  signal ReadPosition : integer range 0 to 63;
  signal ReadLineLength : integer range 0 to 63;

  constant StatusCommand : string := "status";
  constant HelpCommand : string := "help";

  signal BannerPrintState : unsigned(MAX_STATE_HIGH_IDX downto 0);
  signal BannerStringPosition : integer range 0 to MAX_STRING_HIGH_IDX;

  signal Rst : std_logic;

  signal EngineStatus : std_logic_vector(31 downto 0);

begin

    Rst <= not nRst;

    REPL : process (Clk, Rst)
      constant StateIdle0 : std_logic_vector(7 downto 0) := x"00";
      constant StateRead0 : std_logic_vector(7 downto 0) := x"01";
      constant StateRead1 : std_logic_vector(7 downto 0) := x"02";
      constant StateRead2 : std_logic_vector(7 downto 0) := x"03";
      constant StateRead3 : std_logic_vector(7 downto 0) := x"04";
      constant StateRead4 : std_logic_vector(7 downto 0) := x"05";
      constant StateRead5 : std_logic_vector(7 downto 0) := x"06";
      constant StateEval0 : std_logic_vector(7 downto 0) := x"07";
      constant StateEval1 : std_logic_vector(7 downto 0) := x"08";
      constant StateEcho0 : std_logic_vector(7 downto 0) := x"09";
      constant StateUnknownCommand : std_logic_vector(7 downto 0) := x"0A";
      constant StatePrompt0 : std_logic_vector(7 downto 0) := x"0B";
      constant StateHelpCommand0 : std_logic_vector(7 downto 0) := x"0C";
      constant StateStatusCommand0 : std_logic_vector(7 downto 0) := x"0D";
      constant StateStatusCommand1 : std_logic_vector(7 downto 0) := x"0E";
      constant StateStatusCommand2 : std_logic_vector(7 downto 0) := x"0F";
      constant StateStatusCommand3: std_logic_vector(7 downto 0) := x"10";
    begin
        if Rst = '1' then
            Uart_Adr <= (others => '0');
            Uart_Sel <= (others => '0');
            Uart_We <= '0';
            Uart_Stb <= '0';
            Uart_Cyc <= "0";
            Uart_DatIn <= (others => '0');
            Debug_Adr <= (others => '0');
            Debug_Sel <= (others => '0');
            Debug_We <= '0';
            Debug_Stb <= '0';
            Debug_Cyc <= "0";
            Debug_DatIn <= (others => '0');
            EngineStatus <= (others => '0');
            ReadLine <= (others => (others => '0'));
            ReadPosition <= 0;
            ReadLineLength <= 0;
            BannerPrintState <= (others => '0');
            BannerStringPosition <= 0;
            State <= StateIdle0;
        elsif rising_edge(clk) then
            -- Avoid implicit latch inference
            Debug_DatIn <= (others => '0');
            if (State = StateIdle0) then
                print(banner,
                        BannerPrintState,
                        BannerStringPosition,
                        Uart_Adr,
                        Uart_Sel,
                        Uart_DatOut,
                        Uart_We,
                        Uart_Stb,
                        Uart_Cyc,
                        Uart_DatIn,
                        Uart_Ack);
                if( BannerPrintState = stateExit ) then
                    BannerPrintState <= (others => '0');
                    State <= StatePrompt0;
                end if;
            --
            -- Wait for UART TX input
            --
            elsif (State = StatePrompt0) then
                print("WASM> ",
                        BannerPrintState,
                        BannerStringPosition,
                        Uart_Adr,
                        Uart_Sel,
                        Uart_DatOut,
                        Uart_We,
                        Uart_Stb,
                        Uart_Cyc,
                        Uart_DatIn,
                        Uart_Ack);
                if( BannerPrintState = stateExit ) then
                    BannerPrintState <= (others => '0');
                    State <= StateRead0;
                end if;
            elsif (State = StateRead0) then
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '0';
                Uart_Adr <= WASMFPGAUART_ADR_StatusReg;
                state <= StateRead1;
            elsif (State = StateRead1) then
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= "0";
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    if (Uart_DatOut(2) = WASMFPGAUART_VAL_RxDataIsPresent) then
                        state <= StateRead2;
                    else
                        state <= StateRead0;
                    end if;
                end if;
            elsif (State = StateRead2) then
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_ControlReg;
                Uart_DatIn <= (31 downto 2 => '0') & WASMFPGAUART_VAL_RxDoRun & '0';
                State <= StateRead3;
            elsif (State = StateRead3) then
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= "0";
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    State <= StateRead4;
                end if;
            elsif (State = StateRead4) then
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '0';
                Uart_Adr <= WASMFPGAUART_ADR_RxDataReg;
                State <= StateRead5;
            elsif (State = StateRead5) then
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= "0";
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    ReadLine(ReadPosition) <= Uart_DatOut(7 downto 0);
                    ReadPosition <= ReadPosition + 1;
                    if (Uart_DatOut(7 downto 0) = x"0D") then
                        ReadLineLength <= ReadPosition + 1;
                        State <= StateEval0;
                    else
                        State <= StateEcho0;
                    end if;
                end if;
            elsif (State = StateEcho0) then
                printc (ReadLine(ReadPosition - 1),
                       BannerPrintState,
                       Uart_Adr,
                       Uart_Sel,
                       Uart_DatOut,
                       Uart_We,
                       Uart_Stb,
                       Uart_Cyc,
                       Uart_DatIn,
                       Uart_Ack);
                if( BannerPrintState = stateExit ) then
                    BannerPrintState <= (others => '0');
                    State <= StateRead0;
                end if;
            --
            -- Evaluate and dispatch input
            --
            elsif (State = StateEval0) then
                print(CR & LF,
                        BannerPrintState,
                        BannerStringPosition,
                        Uart_Adr,
                        Uart_Sel,
                        Uart_DatOut,
                        Uart_We,
                        Uart_Stb,
                        Uart_Cyc,
                        Uart_DatIn,
                        Uart_Ack);
                if( BannerPrintState = stateExit ) then
                    BannerPrintState <= (others => '0');
                    State <= StateEval1;
                end if;
            elsif (State = StateEval1) then
                if strcmp(ReadLine, to_byte_array(HelpCommand)) = '1' then
                  State <= StateHelpCommand0;
                elsif strcmp(ReadLine, to_byte_array(StatusCommand)) = '1' then
                  State <= StateStatusCommand0;
                else
                  State <= StateUnknownCommand;
                end if;
            elsif (State = StateHelpCommand0) then
                print("Help!" & CR & LF,
                        BannerPrintState,
                        BannerStringPosition,
                        Uart_Adr,
                        Uart_Sel,
                        Uart_DatOut,
                        Uart_We,
                        Uart_Stb,
                        Uart_Cyc,
                        Uart_DatIn,
                        Uart_Ack);
                if( BannerPrintState = stateExit ) then
                    ReadLine <= (others => (others => '0'));
                    ReadPosition <= 0;
                    BannerPrintState <= (others => '0');
                    State <= StatePrompt0;
                end if;
            elsif (State = StateStatusCommand0) then
                Debug_Cyc <= "1";
                Debug_Stb <= '1';
                Debug_Sel <= (others => '1');
                Debug_We <= '0';
                Debug_Adr <= WASMFPGAENGINEDEBUG_ADR_StatusReg;
                State <= StateStatusCommand1;
            elsif (State = StateStatusCommand1) then
                if ( Debug_Ack = '1' ) then
                    Debug_Cyc <= "0";
                    Debug_Stb <= '0';
                    Debug_Adr <= (others => '0');
                    Debug_Sel <= (others => '0');
                    Debug_We <= '0';
                    EngineStatus <= Debug_DatOut;
                    State <= StateStatusCommand2;
                end if;
            elsif (State = StateStatusCommand2) then
                print_int32("Status: 0x",
                            EngineStatus,
                            BannerPrintState,
                            BannerStringPosition,
                            Uart_Adr,
                            Uart_Sel,
                            Uart_DatOut,
                            Uart_We,
                            Uart_Stb,
                            Uart_Cyc,
                            Uart_DatIn,
                            Uart_Ack);
                if( BannerPrintState = stateExit ) then
                    ReadLine <= (others => (others => '0'));
                    ReadPosition <= 0;
                    BannerPrintState <= (others => '0');
                    State <= StateStatusCommand3;
                end if;
            elsif (State = StateStatusCommand3) then
                print(CR & LF,
                        BannerPrintState,
                        BannerStringPosition,
                        Uart_Adr,
                        Uart_Sel,
                        Uart_DatOut,
                        Uart_We,
                        Uart_Stb,
                        Uart_Cyc,
                        Uart_DatIn,
                        Uart_Ack);
                if( BannerPrintState = stateExit ) then
                    BannerPrintState <= (others => '0');
                    State <= StatePrompt0;
                end if;
            elsif (State = StateUnknownCommand) then
                print("Command not found" & CR & LF,
                        BannerPrintState,
                        BannerStringPosition,
                        Uart_Adr,
                        Uart_Sel,
                        Uart_DatOut,
                        Uart_We,
                        Uart_Stb,
                        Uart_Cyc,
                        Uart_DatIn,
                        Uart_Ack);
                if( BannerPrintState = stateExit ) then
                    ReadLine <= (others => (others => '0'));
                    ReadPosition <= 0;
                    BannerPrintState <= (others => '0');
                    State <= StatePrompt0;
                end if;
            end if;
        end if;
    end process;

end;
