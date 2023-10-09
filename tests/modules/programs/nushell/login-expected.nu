# Prints "Hello, World" upon logging into tty1
if (tty) == "/dev/tty1" {
  echo "Hello, World"
}

