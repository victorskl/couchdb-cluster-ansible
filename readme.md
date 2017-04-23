## CouchDB Cluster using Ansible
This will setup CouchDB Cluster using Ansible. Software stack are:

#### Server
* CouchDB 2.0
* Ubuntu 16.04 Server

#### Control Station
* Ansible 2.2.2
* Windows 10 with _Bash on Ubuntu on Windows_

#### Local Development
* VirtualBox

## How to

### VirutalBox Cluster

> #### Note: 
> You may skip this if you are attempting on some cloud infrastructure. 

* Setup VirtualBox with 3 Ubuntu Server guests
* Create VirtualBox _Host-only Network_ using subnet 192.168.56.0/24
    * File > Preferences > Network > Host-only Network tab > Adds new host-only network
    * Double click newly added network, specify:
        * IPv4 Address:  192.168.56.1
        * IPv4 Network Mask:  255.255.255.0
        * Do not enable DHCP Server
    
* Each Ubuntu Server guest should have:
    * 2 Network interfaces:
        * NAT
        * Host-only Adapter (_use the adapter created in Host-only Network setup step above_)

* Install each Ubuntu Server guest, using default network interface with NAT i.e. select `enp0s3`. After OS installation completed, reboot.
 
* Login and setup hostname and static IP for the second network interface  i.e. Host-only Adapter `enp0s8`.
    * `vi /etc/hosts` change `127.0.0.1 ubuntu` to `127.0.0.1 couchdb1`
    * `vi /etc/hostname` change `ubuntu` to `couchdb1`
    * `vi /etc/network/interfaces` and add
    ```
    auto enp0s8
    iface enp0s8 inet static
    address 192.168.56.101
    netmask 255.255.255.0
    ```
    * Reboot
    * Repeat these steps for each Ubuntu Server guest. You will get the following cluster.
    ```
    couchdb1,192.168.56.101
    couchdb2,192.168.56.102
    couchdb3,192.168.56.103
    ```
    
### Control Station (Windows 10)

> #### Note: 
> You may skip this if your control station is not Windows 10. Just make sure you have Ansible.

* Setup [Bash on Ubuntu on Windows](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide) and launch it.

* Populate SSH Fingerprint to known_hosts `bash knownhosts.sh`.

* Setup [Python3 and Ansible on Windows](https://github.com/victorskl/nectar-boto-ansible-tute#notes-for-ansible-on-windows).
    ```
    which python
    python3 -V
    sudo apt install python3-pip
    which pip3
    pip3 -V
    sudo apt install libffi-dev python3-dev
    pip3 install ansible --user
    echo 'PATH=$HOME/.local/bin:$PATH' >> .bashrc
    source .bashrc
    which ansible
    which ansible-playbook
    ansible --version
    ```

### Install CouchDB Cluster

* Install `python-minimal` on Ubuntu guests. This may or may not require if you use it on some cloud [distro](https://en.wikipedia.org/wiki/Linux_distribution) on OpenStack, AWS. On [NeCTAR](https://nectar.org.au/research-cloud/), this is not required. Change `victorskl` with your Ubuntu guest username.
    ```
    bash play.sh victorskl ubuntu-minimal-python.yaml
    ```

* Optional: test it.
    ```
    bash play.sh victorskl test.yaml
    ```
    
* Install CouchDB Cluster
    ```
    bash play.sh victorskl couchdb.yaml
    ```

### Configure CouchDB Cluster

* Go to `http://192.168.56.101:5984/_utils/#setup/multinode`

* At Specify Credentials, Admin Username: `cadmin`, Admin Password: `password`

* At Add Nodes, Remote host: `192.168.56.102` and then press `Add Node` button.

* Optional: repeat for adding all nodes i.e. as define in `hosts.ini`.

* After adding nodes, press `Configure Cluster` button.

* Check the newly setup cluster membership.
    ```
    curl http://cadmin:password@192.168.56.101:5984/_membership
    ```

* Note: you only need to do above steps on one node. The other participating node will auto pick up the membership. In fact, check that `couchdb2` return the same.
  ```
  curl http://cadmin:password@192.168.56.102:5984/_membership
  ```

### Add Nodes to CouchDB Cluster

* Modify `hosts.ini` to:
    ```
    [couchdbs]
    #192.168.56.101
    #192.168.56.102
    192.168.56.103
    ```

* Repeat [Install CouchDB Cluster](#install-couchdb-cluster) steps for newly added node(s).

* Add new nodes to the existing cluster.
    ```
    curl -X PUT "http://cadmin:password@192.168.56.101:5986/_nodes/couchdb@192.168.56.103" -d {}
    ```

* Check the cluster membership.
    ```
    curl http://cadmin:password@192.168.56.101:5984/_membership
    ```

    ![couchdb_cluster_membership.jpg](img/couchdb_cluster_membership.jpg)

### Sharding

* Say, create `test` database with 4-shards and 2-replica.
    ```
    curl -X PUT "http://cadmin:password@192.168.56.101:5984/test?q=4&n=2"
    ```

    ![couchdb_sharding_q4_n2.png](img/couchdb_sharding_q4_n2.jpg)


* Observe the `test` database shard/replica distribution on cluster. Note: port number is **:5986**.
    ```
    curl -X GET "http://cadmin:password@192.168.56.101:5986/_dbs/test"
    ```

    ![couchdb_cluster_shard_1.png](img/couchdb_cluster_shard_1.jpg)

    ![couchdb_cluster_shard_2.png](img/couchdb_cluster_shard_2.jpg)
    
