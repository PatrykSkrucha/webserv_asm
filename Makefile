NAME    = server
SRCS    = server.s
OBJS    = $(SRCS:.s=.o)
AS      = as
LD      = ld

all: $(NAME)

$(NAME): $(OBJS)
	$(LD) $(OBJS) -o $(NAME)

%.o: %.s
	$(AS) $< -o $@

clean:
	rm -f $(OBJS)

fclean: clean
	rm -f $(NAME)

re: fclean all

.PHONY: all clean fclean re
