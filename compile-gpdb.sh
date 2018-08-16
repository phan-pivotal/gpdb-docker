chown -R gpadmin_dev:gpadmin /src
su - gpadmin_dev

scl enable python27 devtoolset-7 bash

./configure 	--with-perl --with-python --with-libxml --enable-debug --enable-cassert \
--disable-orca --disable-gpcloud --prefix=$HOME/gpdb.master
make
make install

cd gpAux/gpdemo
source $HOME/gpdb.master/greenplum_path.sh
export PGHOST=`hostname`
make
source gpdemo-env.sh

psql
postgres#SELECT version()