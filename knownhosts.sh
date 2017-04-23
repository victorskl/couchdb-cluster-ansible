#!/bin/bash

# Populate SSH Fingerprint to known_hosts
cd ~
ssh-keyscan couchdb1,192.168.56.101 >> ~/.ssh/known_hosts
ssh-keyscan couchdb2,192.168.56.102 >> ~/.ssh/known_hosts
ssh-keyscan couchdb3,192.168.56.103 >> ~/.ssh/known_hosts