FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install -y nano python3-pip python3-dbg strace ltrace gdb

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN pip install numpy --break-system-packages

RUN mkdir /app
WORKDIR /app

COPY script/ /app/
CMD ["bash"]