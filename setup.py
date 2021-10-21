import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

__tag__ = ""
__build__ = 0
__version__ = "{}".format(__tag__)
__commit__ = "0000000"

setuptools.setup(
    name="wasm-fpga-debug",
    version=__version__,
    author="Denis Vasilìk",
    author_email="contact@denisvasilik.com",
    url="https://github.com/denisvasilik/wasm-fpga-debug/",
    project_urls={
        "Bug Tracker": "https://github.com/denisvasilik/wasm-fpga/",
        "Documentation": "https://wasm-fpga.readthedocs.io/en/latest/",
        "Source Code": "https://github.com/denisvasilik/wasm-fpga-debug/",
    },
    description="WebAssembly FPGA Debug",
    long_description=long_description,
    long_description_content_type="text/markdown",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3.6",
        "Operating System :: OS Independent",
    ],
    dependency_links=[],
    package_dir={},
    package_data={},
    data_files=[(
        "wasm-fpga-debug/package", [
            "package/component.xml"
        ]),(
        "wasm-fpga-debug/package/bd", [
            "package/bd/bd.tcl"
        ]),(
        "wasm-fpga-debug/package/xgui", [
            "package/xgui/wasm_fpga_debug_v1_0.tcl"
        ]),(
        "wasm-fpga-debug/resources", [
            "resources/wasm_fpga_uart_header.vhd",
            "resources/wasm_fpga_uart_wishbone.vhd",
        ]),(
        "wasm-fpga-debug/src", [
            "src/WasmFpgaDebug.vhd",
            "src/WasmFpgaDebugPackage.vhd"
        ]),(
        "wasm-fpga-debug/tb", [
            "tb/tb_FileIo.vhd",
            "tb/tb_pkg_helper.vhd",
            "tb/tb_pkg.vhd",
            "tb/tb_std_logic_1164_additions.vhd",
            "tb/tb_Types.vhd",
            "tb/tb_UartModel.vhd",
            "tb/tb_WasmFpgaDebug.vhd",
        ]),(
        'wasm-fpga-debug/simstm', [
            'simstm/Defines.stm',
            'simstm/WasmFpgaDebug.stm',
        ]),(
        "wasm-fpga-debug", [
            "CHANGELOG.md",
            "AUTHORS",
            "LICENSE"
        ])
    ],
    setup_requires=[],
    install_requires=[],
    entry_points={},
)
