all:
	nasm -f bin mmapviewer.asm
	qemu-system-i386 -fda mmapviewer
