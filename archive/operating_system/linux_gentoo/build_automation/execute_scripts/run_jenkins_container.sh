#!/bin/bash

mkdir -p $HOME/my/data/for_services/jenkins
sudo docker run -p 8080:8080 -p 50000:50000 -v $HOME/my/data/for_services/jenkins:/var/jenkins_home jenkins
