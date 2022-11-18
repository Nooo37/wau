#!/bin/sh

# colors for output

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# start the compositor and retrieve the socket path

SOCKET=

echo -e "${CYAN}USING DEFAULT SOCKET${NC}"
echo

# run the tests

cd .. # position such that ./wau as a module exists

FAILED_COUNT=0

for i in $(ls ./tests/test-*.lua); do
	printf "${CYAN}TEST:${NC} $i"
	if output=$(lua -e "dofile('$i')" 2>&1); then
		echo -e " -> ${GREEN}SUCCESS${NC}"
	else
		echo -e " -> ${RED}FAILED${NC}"
		FAILED_COUNT=$((FAILED_COUNT + 1))
	fi
	echo "$output" | sed "s/^/    /"
done


# cleanup

unset SOCKET
unset RED GREEN CYAN NC

exit $FAILED_COUNT

