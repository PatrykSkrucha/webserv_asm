# webserv_asm

> A tiny HTTP server written in **pure x86-64 assembly**: no libc, no runtime, just Linux syscalls.

![Assembly](https://img.shields.io/badge/x86--64-Assembly-555555?style=flat&logo=intel&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-syscalls-FCC624?style=flat&logo=linux&logoColor=black)

## About

`webserv_asm` is a minimal web server that talks to the kernel directly. It opens a TCP socket,
accepts connections and forks a child process for every client, which parses the request by hand
and answers it. The whole server is a single file, [`server.s`](server.s), written in GNU `as` Intel syntax.

## Features

- **GET**: reads the requested file and returns it with `HTTP/1.0 200 OK`
- **POST**: finds the body after the `\r\n\r\n` header terminator and writes it to the requested path (the file is created if needed)
- **Concurrent clients**: one `fork()` per connection, the parent keeps accepting
- **Zero dependencies**: only `socket`, `bind`, `listen`, `accept`, `fork`, `read`, `write`, `open`, `close` and `exit`

## How it works

```
socket() → bind(0.0.0.0:80) → listen()
   └─ loop: accept() → fork()
        ├─ parent: close(client) → accept next
        └─ child:  read(request)
                   ├─ "GET <path>"  → open → read → write header + file
                   ├─ "POST <path>" → open(O_WRONLY|O_CREAT) → write body
                   └─ close(client) → exit
```

| Register | Role |
|---|---|
| `r12` | listening socket |
| `r13` | client socket |
| `r14` | file path (POST) / bytes read (GET) |
| `r15` | start of the request body |
| `rbx` | request / body length |

## Build & run

Requires Linux x86-64 and GNU binutils.

```bash
make
sudo ./server        # listens on port 80
```

Or by hand: `as server.s -o server.o && ld server.o -o server`.

## Try it

```bash
# upload a file (the URL path is used as an absolute filesystem path)
curl -X POST --data "hello from curl" http://localhost/tmp/hello.txt

# fetch it back
curl http://localhost/tmp/hello.txt
```

## Limitations

This is a learning project, not a production server:
requests and files are limited to **1024 bytes**, only `GET` and `POST` are recognised,
there is no path sanitisation (do not expose it to a network), and errors are not reported to the client.
