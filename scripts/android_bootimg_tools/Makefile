CC					:= gcc
CFLAGS				:= -I. -Iinclude -Ilibmincrypt/include -O2 -ffunction-sections
LDFLAGS				:= -Wl,--gc-sections -L.

RM					:= rm -f

MKBOOTFS_SRC		:= mkbootfs.c fs_config.c
MKBOOTIMG_SRC		:= mkbootimg.c
UNPACKBOOTIMG_SRC	:= unpackbootimg.c

all: mkbootfs mkbootimg unpackbootimg

libmincrypt.a:
	make -C libmincrypt

mkbootfs: $(MKBOOTFS_SRC)
	$(CROSS_COMPILE)$(CC) $(CFLAGS) $(MKBOOTFS_SRC) -o mkbootfs $(LDFLAGS)

mkbootimg: libmincrypt.a $(MKBOOTIMG_SRC)
	$(CROSS_COMPILE)$(CC) $(CFLAGS) $(MINCRYPT_SRC) $(MKBOOTIMG_SRC) -o mkbootimg $(LDFLAGS) -lmincrypt

unpackbootimg: libmincrypt.a $(UNPACKBOOTIMG_SRC)
	$(CROSS_COMPILE)$(CC) $(CFLAGS) $(MINCRYPT_SRC) $(UNPACKBOOTIMG_SRC) -o unpackbootimg $(LDFLAGS) -lmincrypt

clean:
	$(RM) mkbootfs mkbootimg unpackbootimg libmincrypt.a
	make -C libmincrypt clean
