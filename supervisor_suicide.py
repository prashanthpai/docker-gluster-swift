#!/usr/bin/env python
import os
import signal
import sys


def write_stdout(s):
    # only eventlistener protocol messages may be sent to stdout
    sys.stdout.write(s)
    sys.stdout.flush()


def write_stderr(s):
    sys.stderr.write(s)
    sys.stderr.flush()


def main():
    while True:
        # transition from ACKNOWLEDGED to READY
        write_stdout('READY\n')

        # read header line and consume
        line = sys.stdin.readline()
        try:
            with open("/var/run/supervisord.pid") as f:
                os.kill(int(f.readline()), signal.SIGQUIT)
        except Exception as err:
            write_stderr("Supervisor not killed: %s\n" % (err.strerror))

        # transition from READY to ACKNOWLEDGED
        write_stdout('RESULT 2\nOK')

if __name__ == '__main__':
    main()
