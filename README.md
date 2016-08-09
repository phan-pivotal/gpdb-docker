# gptext-docker
GPTEXT for Pivotal Greenplum Database Base Docker Image (4.3.7.1)

# Building the Docker Image
You will first need to download the GPTEXT for Pivotal Greenplum Database 4.3.7.1 RHEL installer (.zip) located at https://network.pivotal.io/products/pivotal-gpdb and oracle jre 8 or above for linux x64 from //download.oracle.com/otn-pub/java/jdk/8u92-b14/jre-8u92-linux-x64.rpm ,and place them inside gptext directory .

cd [docker working directory]

docker build -t [tag] .

# Running the Docker Image
docker run -i -p 5432:5432 [tag]

# Container Accounts
root/pivotal

gpadmin/pivotal

# Using psql in the Container
su - gpadmin

psql

# Using pgadmin outside the Container
Launch pgAdmin3

Create new connection using IP Address and Port # (5432)
