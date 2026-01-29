#!/bin/bash
flyway -url=jdbc:mysql://mysqlServer/jeremy_project1 \
       -user=fakeAirbnbUser \
       -password=apples11Million \
       -locations=filesystem:/workspace/sql/migrations/jeremy_project1 \
       migrate