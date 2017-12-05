CC = gcc
AR = ar rc
RM = rm -f
CP = cp

CFLAGS = -ffunction-sections -O2
EXT = a
LIB = libmincrypt.$(EXT)
LIB_OBJS = dsa_sig.o p256.o p256_ec.o p256_ecdsa.o rsa.o sha.o sha256.o
INC  = -Iinclude

all:$(LIB)

clean:
	$(RM) $(LIB_OBJS) $(LIB)

$(LIB):$(LIB_OBJS)
	$(CROSS_COMPILE)$(AR) $@ $^
	$(CP) $@ ..


%.o:%.c
	$(CROSS_COMPILE)$(CC) -o $@ $(CFLAGS) -c $< $(INC)
