#!/bin/bash

#make some simulations, first day, by day

#./do_simulate.bash -b lay  -a hound -n Plats 
#./do_simulate.bash -b back -a hound -n Plats
#./do_simulate.bash -b lay  -a horse -n Plats 
#./do_simulate.bash -b back -a horse -n Plats
#./do_simulate.bash -b lay  -a hound -n Vinnare 
#./do_simulate.bash -b back -a hound -n Vinnare
#./do_simulate.bash -b lay  -a horse -n Vinnare
#./do_simulate.bash -b back -a horse -n Vinnare

## then over two days
#./do_simulate.bash -b lay  -a hound -n Plats   -u -s "2013-01-30" -t "2013-01-31"
#./do_simulate.bash -b back -a hound -n Plats   -u -s "2013-01-30" -t "2013-01-31"
#./do_simulate.bash -b lay  -a horse -n Plats   -u -s "2013-01-30" -t "2013-01-31"
#./do_simulate.bash -b back -a horse -n Plats   -u -s "2013-01-30" -t "2013-01-31"
#./do_simulate.bash -b lay  -a hound -n Vinnare -u -s "2013-01-30" -t "2013-01-31" 
#./do_simulate.bash -b back -a hound -n Vinnare -u -s "2013-01-30" -t "2013-01-31"
#./do_simulate.bash -b lay  -a horse -n Vinnare -u -s "2013-01-30" -t "2013-01-31"
#./do_simulate.bash -b back -a horse -n Vinnare -u -s "2013-01-30" -t "2013-01-31"



(python simulator.py --bet_type=lay --bet_name=Plats \
  --start_date=2013-01-30 --stop_date=2013-02-01 --saldo=10000 \
  --size=30 --animal=horse --min_price=1.0 --max_price=30 --summary  && \
python simulator.py --bet_type=back --bet_name=Plats \
  --start_date=2013-01-30 --stop_date=2013-02-01 --saldo=10000 \
  --size=30 --animal=horse --min_price=1.0 --max_price=30 --summary  ) &
  
(python simulator.py --bet_type=lay --bet_name=Plats \
  --start_date=2013-01-30 --stop_date=2013-02-01 --saldo=10000 \
  --size=30 --animal=hound --min_price=1.0 --max_price=30 --summary  && \
python simulator.py --bet_type=back --bet_name=Plats \
  --start_date=2013-01-30 --stop_date=2013-02-01 --saldo=10000 \
  --size=30 --animal=hound --min_price=1.0 --max_price=30 --summary  ) &

(python simulator.py --bet_type=lay --bet_name=Vinnare \
  --start_date=2013-01-30 --stop_date=2013-02-01 --saldo=10000 \
  --size=30 --animal=horse --min_price=1.0 --max_price=30 --summary  && \
python simulator.py --bet_type=back --bet_name=Vinnare \
  --start_date=2013-01-30 --stop_date=2013-02-01 --saldo=10000 \
  --size=30 --animal=horse --min_price=1.0 --max_price=30 --summary  ) &

(python simulator.py --bet_type=lay --bet_name=Vinnare \
  --start_date=2013-01-30 --stop_date=2013-02-01 --saldo=10000 \
  --size=30 --animal=hound --min_price=1.0 --max_price=30 --summary  && \
python simulator.py --bet_type=back --bet_name=Vinnare \
  --start_date=2013-01-30 --stop_date=2013-02-01 --saldo=10000 \
  --size=30 --animal=hound --min_price=1.0 --max_price=30 --summary ) &


