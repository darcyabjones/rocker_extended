#!/usr/bin/env python

import socket
s = socket.socket()
s.bind(('', 0))

print(s.getsockname()[1])
s.close()
