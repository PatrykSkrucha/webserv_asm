NAME    = libasm.a
SRCS    = itoa.s
OBJS    = $(SRCS:.s=.o)
NASM    = as
NFLAGS  = 
CC      = cc

all: $(NAME)

$(NAME): $(OBJS)
	ar rcs $(NAME) $(OBJS)

%.o: %.s
	$(NASM) $(NFLAGS) $< -o $@

main.o: main.c
	$(CC) -c $< -o $@

test: main.o $(NAME)
	$(CC) $^ -o $@

clean:
	rm -f $(OBJS) main.o

fclean: clean
	rm -f $(NAME) test

re: fclean all

.PHONY: all clean fclean re