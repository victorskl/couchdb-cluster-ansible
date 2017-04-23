#!/bin/bash

ansible-playbook -i hosts.ini -u $1 -k -b --become-method=sudo -K $2