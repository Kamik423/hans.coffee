#! /usr/bin/env python3
import sys


def main() -> None:
    print("".join(r"\symbol{" + str(ord(c)) + r"}" for c in sys.argv[1]))


if __name__ == "__main__":
    main()
