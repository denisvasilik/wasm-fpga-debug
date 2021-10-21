PWD=$(shell pwd)

all: package

prepare:
	@mkdir -p work

fetch-resources:
	cp ../wasm-fpga-uart/resources/wasm_fpga_uart_wishbone.vhd resources/
	cp ../wasm-fpga-uart/resources/wasm_fpga_uart_header.vhd resources/

project: prepare fetch-resources
	@vivado -mode batch -source scripts/create_project.tcl -notrace -nojournal -tempDir work -log work/vivado.log

package: fetch-resources
	python3 setup.py sdist bdist_wheel

clean:
	@rm -rf .Xil vivado*.log vivado*.str vivado*.jou
	@rm -rf work \
		src-gen \
		dist \
		*.egg-info

install-from-test-pypi:
	pip3 install --upgrade -i https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple wasm-fpga-debug

upload-to-test-pypi: package
	python3 -m twine upload --repository-url https://test.pypi.org/legacy/ dist/*

upload-to-pypi: package
	python3 -m twine upload --repository pypi dist/*

.PHONY: all prepare project package clean hxs
