#!/bin/sh
#
# by Sairon Istyar, 2012
# distributed under the GPLv3 license
# http://www.opensource.org/licenses/gpl-3.0.html
#

# program to use for torrent download
program='/usr/bin/transmission-remote'
progopts='-a'
# show N first matches by default
limit=15
# colors
numbcolor='\x1b[1;35m'
namecolor='\x1b[1;33m'
sizecolor='\x1b[1;36m'
seedcolor='\x1b[1;31m'
peercolor='\x1b[1;32m'
errocolor='\x1b[1;31m'
mesgcolor='\x1b[1;37m'
nonecolor='\x1b[0m'

thisfile="$0"

printhelp() {
	echo -e "Usage:"
	echo -e "\t$thisfile [options] search query"
	echo
	echo
	echo -e "Available options:"
	echo -e "\t-h\t\tShow help"
	echo -e "\t-n [num]\tShow only first N results (default 15; max 50)"
	echo -e "\t-C\t\tDo not use colors"
	echo -e "\t-P [prog]\tSet torrent client"
	echo -e "\t-O [opts]\tSet torrent client cmdline options"
	echo
	echo -e "Current client settings: $program $progopts [magnet link]"
}

# change torrent client
chex() {
	sed "s!^program=.*!program=\'$program\'!" -i "$thisfile"
	if [ $? -eq 0 ] ; then
		echo "Client changed successfully."
		exit 0
	else
		echo -e "${errocolor}(EE) ${mesgcolor}==> Something went wrong!${nonecolor}"
		exit 1
	fi
}

# change torrent client options
charg() {
	sed "s!^progopts=.*!progopts=\'$progopts\'!" -i "$thisfile"
	if [ $? -eq 0 ] ; then
                echo "Cmdline options for client changed successfully."
                exit 0
        else 
                echo -e "${errocolor}(EE) ${mesgcolor}==> Something went wrong!${nonecolor}"
                exit 1
        fi
}

# script cmdline option handling
while getopts :hn:CP:O:: opt ; do
	case "$opt" in
		h) printhelp; exit 0;;
		n) limit="$OPTARG";;
		C) unset numbcolor namecolor sizecolor seedcolor peercolor nonecolor errocolor mesgcolor;;
		P) program="$OPTARG"; chex;;
		O) progopts="$OPTARG"; charg;;
		*) echo -e "Unknown option(s)."; printhelp; exit 1;;
	esac
done

shift `expr $OPTIND - 1`

# correctly encode query
q=`echo "$*" | tr -d '\n' | od -t x1 -A n | tr ' ' '%'`

# get results
r=`curl -s "http://torrentz.eu/search?f=$q" \
	| grep -Eo '<dl><dt><a href=\"\/[[:alnum:]]*\">.*</a>|<span class=\"[speud]*\">[^<]*</span>' \
	| sed 's!<dl><dt><a href=\"/!!; \
		s!\">!|!; \
		s!<[/]*b>!!g; \
		N;N;N;s!\n<span class=\"[pesud]*\">!|!g; \
		s!</span>!!g; \
		s!</a>!!'`

# number of results
n=`echo "$r" | wc -l`

IFS=$'\n'

# print results
echo "$r" \
	| head -n "$limit" \
	| awk -v N=1 \
		-v NU="$numbcolor" \
		-v NA="$namecolor" \
		-v SI="$sizecolor" \
		-v SE="$seedcolor" \
		-v PE="$peercolor" \
		-v NO="$nonecolor" \
		-F '|' \
		'{print NU N ") " NA $2 " " SI $3 " " SE $4 " " PE $5 NO; N++}'

# read ID, ignore every character except digits
read -p ">> Enter torrent No. to download: " down
down=`echo "$down" | sed 's/[^[:digit:]]*//g' | head -n 1`

# check if ID is valid and in range of results, download torrent
if [ -z "$down" ] ; then
	echo "Not a number!"
	unset IFS
	exit 1
elif [ $down -ge 1 ] ; then
	if [ $down -le $limit ] ; then
		echo "Downloading..."
		$program $progopts "`echo "$r" | awk -F '|' 'NR=='$down'{print "magnet:?xt=urn:btih:" $1; exit}'`"
	else
		echo "Number too high! ($down)"
		unset IFS
		exit 3
	fi
else
	echo "Number too low! ($down)"
	unset IFS
	exit 2
fi

unset IFS