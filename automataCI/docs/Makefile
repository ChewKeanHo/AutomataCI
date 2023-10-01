unexport LC_ALL
LC_COLLATE=C
LC_NUMERIC=C
export LC_COLLATE LC_NUMERIC
unexport GREP_OPTIONS

RM		:= rm -f
NON_VERBOSE	:= -s

ifdef ARCH
CC		= $(ARCH)-gcc
OBJCOPY		= $(ARCH)-objcopy
else
CC		= gcc
OBJCOPY		= objcopy
endif
STATIC_TEST	= flawfinder
BASHELL_TEST	= ./bashell.sh

PROJECT_PATH	= .
INCLUDE_PATH	= includes
LIBRARY_PATH	= libs
BINARY_PATH	= bin

MAIN_CODE	= main.c
MAIN_OBJECT	= $(BINARY_PATH)/${MAIN_CODE:.c=.o}
MAIN_BIN	= $(BINARY_PATH)/${MAIN_CODE:.c=.bin}
MAIN_FILES	= $(wildcard $(LIBRARY_PATH)/*.c)
MAIN_OBJECTS	= $(MAIN_FILES:.c=.o)

CFLAGS		+= -I$(INCLUDE_PATH)
CFLAGS		+= -MMD
CFLAGS		+= -Wall
CFLAGS		+= -Wundef
CFLAGS		+= -Wstrict-prototypes
CFLAGS		+= -Wno-trigraphs
CFLAGS		+= -fno-strict-aliasing
CFLAGS		+= -fno-common
CFLAGS		+= -fshort-wchar
CFLAGS		+= -Werror-implicit-function-declaration
CFLAGS		+= -Wno-format-security
CFLAGS		+= -std=gnu89 $(call cc-option, -fno-PIE)
CFLAGS		+= -Os

ifndef CONFIG_VERBOSE
CFLAGS		+= $(NON_VERBOSE)
endif

%.o: %.c
	$(info compiling  : $(@))
	@$(CC) $(CFLAGS) -o $@ -c $<

.PHONY: all
all: $(MAIN_OBJECTS)
	$(info compiling  : $(MAIN_OBJECT))
	@$(CC) $(CFLAGS) -c $(MAIN_CODE) -o $(MAIN_OBJECT)
	$(info linking    : $(MAIN_BIN))
	@$(CC) $(CFLAGS) $(MAIN_OBJECT) $(MAIN_OBJECTS) -o $(MAIN_BIN)

.PHONY: test
test: $(MAIN_FILES)
	$(STATIC_TEST) $(PROJECT_PATH)
	$(BASHELL_TEST) --run

.PHONY: clean
clean: GARBAGE  = *.o
clean: GARBAGE += *.d
clean: GARBAGE += *.elf
clean: GARBAGE += *.hex
clean: GARBAGE += *.bin
clean: GARBAGE += $(BINARY_PATH)/*.o
clean: GARBAGE += $(BINARY_PATH)/*.d
clean: GARBAGE += $(BINARY_PATH)/*.elf
clean: GARBAGE += $(BINARY_PATH)/*.hex
clean: GARBAGE += $(BINARY_PATH)/*.bin
clean: GARBAGE += $(LIBRARY_PATH)/*.o
clean: GARBAGE += $(LIBRARY_PATH)/*.d
clean:
	$(info cleaning   : all *.o, *.d, *.elf, *.bin files)
	@$(RM) $(GARBAGE)
