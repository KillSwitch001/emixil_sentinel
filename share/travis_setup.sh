#!/bin/bash
set -evx

mkdir ~/.emixilcore

# safety check
if [ ! -f ~/.emixilcore/.emixil.conf ]; then
  cp share/emixil.conf.example ~/.emixilcore/emixil.conf
fi
