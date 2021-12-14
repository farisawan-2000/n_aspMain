default: all

DUMMY != mkdir -p build

NON_MATCHING := 0

DEFINES := 
ifeq ($(NON_MATCHING), 1)
	DEFINES += -DNON_MATCHING
endif

all: build/mp3.text.bin
	@sha1sum -c mp3.sha1
	@sha1sum -c mp3data.sha1

tools/armips: tools/armips.cpp
	$(CXX) $(CXXFLAGS) -fno-exceptions -fno-rtti -pipe $^ -o $@ -lpthread $(ARMIPS_FLAGS)
	chmod +x $@

build/mp3.text.bin: mp3.text.s tools/armips
	cpp -P $< -o build/$< -I/usr/include/n64 $(DEFINES)
	tools/armips -strequ CODE_FILE $@ -strequ DATA_FILE build/mp3.data.bin -temp scratch_space/.t3d  build/$<


dump_binary:
	mkdir -p dump
	cpp -P ucode.ld -o build/ucode.cp.ld -DTEXT
	mips-linux-gnu-ld -o dump/text.elf -Tbuild/ucode.cp.ld /usr/lib/n64/PR/gspTurbo3D.fifo.o
	mips-linux-gnu-objcopy dump/text.elf dump/text.bin -O binary
	cpp -P ucode.ld -o build/ucode.cp.ld -DDATA
	mips-linux-gnu-ld -o dump/data.elf -Tbuild/ucode.cp.ld /usr/lib/n64/PR/gspTurbo3D.fifo.o
	mips-linux-gnu-objcopy dump/data.elf dump/data.bin -O binary


clean: build/mp3.text.bin
	rm build/ -r
