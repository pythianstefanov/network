#!/bin/sh
tmsh list ltm virtual| tr -d "\n"|sed 's#}ltm#}\nltm#g'
